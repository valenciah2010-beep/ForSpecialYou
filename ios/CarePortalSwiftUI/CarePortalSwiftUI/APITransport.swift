import Foundation
import CryptoKit
import UIKit

struct APITransport {
    static let sessionExpired = Notification.Name("CarePortalSessionExpired")
    static func send<Response: Decodable>(_ path: String, body: Data, method: String = "POST") async throws -> Response {
        guard let url = APIConfig.baseURL?.appending(path: path) else { throw AuthAPIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let sentToken = SessionStore.token
        if let token = sentToken { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        if path == "/api/health-insights" || path == "/api/analyze-meal" {
            var object = (try JSONSerialization.jsonObject(with: body)) as? [String: Any] ?? [:]
            object["aiConsent"] = true
            request.httpBody = try JSONSerialization.data(withJSONObject: object)
        } else { request.httpBody = body }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AuthAPIError.invalidResponse }
        if http.statusCode == 401 {
            if let sentToken, SessionStore.token == sentToken {
                SessionStore.token = nil
                await MainActor.run {
                    NotificationCenter.default.post(name: sessionExpired, object: nil)
                }
            }
            throw AuthAPIError.server("Please log in again.")
        }
        guard (200..<300).contains(http.statusCode) else {
            let message = (try? JSONDecoder().decode(MessageResponse.self, from: data))?.message
            throw AuthAPIError.server(message ?? "Request failed with status \(http.statusCode)")
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Response.self, from: data)
    }

    @MainActor static func confirmAI() async throws {
        // Scope consent to this login; free text/profile identifiers are excluded on the server.
        let key = "aiConsent." + SHA256.hash(data: Data((SessionStore.token ?? "").utf8)).map { String(format:"%02x",$0) }.joined()
        if UserDefaults.standard.bool(forKey: key) { return }
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              var presenter = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else { throw AuthAPIError.invalidResponse }
        while let next = presenter.presentedViewController { presenter = next }
        let accepted: Bool = await withCheckedContinuation { continuation in
            let alert = UIAlertController(title: localizedAppString("AI analysis"),
                message: localizedAppString("Selected photos and structured health records will be sent to OpenAI. Continue?"), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: localizedAppString("Cancel"), style: .cancel) { _ in continuation.resume(returning: false) })
            alert.addAction(UIAlertAction(title: localizedAppString("Continue"), style: .default) { _ in continuation.resume(returning: true) })
            presenter.present(alert, animated: true)
        }
        guard accepted else { throw CancellationError() }
        UserDefaults.standard.set(true, forKey: key)
    }

    static func upload(_ data: Data) async throws -> String {
        struct Upload: Decodable { let id: String; let chunkBytes: Int }
        struct Status: Decodable { let completed: Bool; let chunks: [Int] }
        struct Chunk: Decodable { let index: Int }
        struct Completed: Decodable { let id: String }
        guard data.count <= 20 * 1024 * 1024 else { throw AuthAPIError.server("Image is too large.") }
        let checksum = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        let owner = SHA256.hash(data: Data((SessionStore.token ?? "").utf8)).map { String(format:"%02x",$0) }.joined()
        let key = "upload.\(owner).\(checksum)"
        var id = UserDefaults.standard.string(forKey: key)
        var received = Set<Int>()
        if let saved = id {
            if let status: Status = try? await send("/api/uploads/\(saved)", body: Data(), method: "GET") {
                if status.completed { return saved }
                received = Set(status.chunks)
            } else { id = nil }
        }
        if id == nil {
            let body = try JSONSerialization.data(withJSONObject: ["size": data.count, "checksum": checksum])
            let upload: Upload = try await send("/api/uploads", body: body)
            id = upload.id
            UserDefaults.standard.set(upload.id, forKey: key)
        }
        guard let uploadID = id else { throw AuthAPIError.invalidResponse }
        let chunkBytes = 512 * 1024
        for offset in stride(from: 0, to: data.count, by: chunkBytes) {
            let index = offset / chunkBytes
            if received.contains(index) { continue }
            try Task.checkCancellation()
            let chunk = data.subdata(in: offset..<min(offset + chunkBytes, data.count))
            let body = try JSONSerialization.data(withJSONObject: ["data": chunk.base64EncodedString()])
            let _: Chunk = try await send("/api/uploads/\(uploadID)/chunks/\(index)", body: body, method: "PUT")
        }
        let result: Completed = try await send("/api/uploads/\(uploadID)/complete", body: Data("{}".utf8))
        return result.id
    }
}
