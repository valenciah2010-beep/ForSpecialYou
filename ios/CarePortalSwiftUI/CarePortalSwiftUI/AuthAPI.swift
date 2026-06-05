import Foundation

enum AuthAPIError: LocalizedError {
    case invalidURL
    case server(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The server address is not valid."
        case .server(let message):
            return message
        case .invalidResponse:
            return "The server sent an unexpected response."
        }
    }
}

struct AuthAPI {
    var baseURL = URL(string: "http://127.0.0.1:3002")

    func login(username: String, password: String) async throws -> CarePortalUser {
        let body = LoginRequest(username: username, password: password)
        let response: AuthResponse = try await post("/api/login", body: body)

        guard let user = response.user else {
            throw AuthAPIError.invalidResponse
        }

        return user
    }

    func signup(nickname: String, email: String, password: String, verifyPassword: String) async throws -> String {
        let body = SignupRequest(
            nickname: nickname,
            username: nickname,
            email: email,
            password: password,
            verifyPassword: verifyPassword,
            role: "parent"
        )
        let response: MessageResponse = try await post("/api/signup", body: body)
        return response.message
    }

    func syncAppData(userId: Int, childProfile: ChildProfileSync?, healthLogs: [HealthLogEntry]?) async throws {
        let body = ParentAppDataSyncRequest(
            userId: userId,
            childProfile: childProfile,
            healthLogs: healthLogs
        )
        let _: MessageResponse = try await post("/api/app-data", body: body)
    }

    private func post<Request: Encodable, Response: Decodable>(_ path: String, body: Request) async throws -> Response {
        guard let url = baseURL?.appending(path: path) else {
            throw AuthAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthAPIError.invalidResponse
        }

        if (200..<300).contains(httpResponse.statusCode) {
            return try JSONDecoder().decode(Response.self, from: data)
        }

        if let errorBody = try? JSONDecoder().decode(MessageResponse.self, from: data) {
            throw AuthAPIError.server(errorBody.message)
        }

        throw AuthAPIError.server("Request failed with status \(httpResponse.statusCode).")
    }
}

struct NutritionAPI {
    var baseURL = URL(string: "http://127.0.0.1:3002")

    func analyzeMeal(imageData: String) async throws -> MealNutritionEstimate {
        guard let url = baseURL?.appending(path: "/api/analyze-meal") else {
            throw AuthAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(MealAnalysisRequest(imageData: imageData))

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthAPIError.invalidResponse
        }

        if (200..<300).contains(httpResponse.statusCode) {
            return try JSONDecoder().decode(MealNutritionEstimate.self, from: data)
        }

        if let errorBody = try? JSONDecoder().decode(MessageResponse.self, from: data) {
            throw AuthAPIError.server(errorBody.message)
        }

        throw AuthAPIError.server("Meal analysis failed with status \(httpResponse.statusCode).")
    }
}

private struct MealAnalysisRequest: Encodable {
    let imageData: String
}

struct ChildProfileSync: Encodable {
    let fullName: String
    let birthDate: String
    let supportNeeds: String
    let homeSchoolNotes: String
    let emergencyContact: String
    let careNotes: String
}

private struct ParentAppDataSyncRequest: Encodable {
    let userId: Int
    let childProfile: ChildProfileSync?
    let healthLogs: [HealthLogEntry]?
}
