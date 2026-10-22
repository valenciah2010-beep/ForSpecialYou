import Foundation
import Security

enum AppSessionToken {
    private static let service = "com.forspecialyou.careportal.session"
    private static let account = "parent-api-token"

    static var value: String? {
        get {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne
            ]
            var result: CFTypeRef?
            guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
                  let data = result as? Data else {
                return nil
            }
            return String(data: data, encoding: .utf8)
        }
        set {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account
            ]
            SecItemDelete(query as CFDictionary)
            guard let newValue else { return }
            var item = query
            item[kSecValueData as String] = Data(newValue.utf8)
            item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            SecItemAdd(item as CFDictionary, nil)
        }
    }
}

enum AuthAPIError: LocalizedError {
    case invalidURL
    case server(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return localizedAppString("The server address is not valid.")
        case .server(let message):
            return localizedServerMessage(message)
        case .invalidResponse:
            return localizedAppString("The server sent an unexpected response.")
        }
    }
}

struct AuthAPI {
    var baseURL = APIConfig.baseURL

    func login(username: String, password: String) async throws -> CarePortalUser {
        let body = LoginRequest(username: username, password: password)
        let response: AuthResponse = try await post("/api/login", body: body)

        guard let user = response.user,
              let token = response.token,
              !token.isEmpty else {
            throw AuthAPIError.invalidResponse
        }

        AppSessionToken.value = token
        return user
    }

    static func clearSession() {
        AppSessionToken.value = nil
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

    func changePassword(userId: Int, currentPassword: String, newPassword: String) async throws -> String {
        let body = ChangePasswordRequest(
            userId: userId,
            currentPassword: currentPassword,
            newPassword: newPassword
        )
        let response: MessageResponse = try await post("/api/change-password", body: body)
        return response.message
    }

    func syncAppData(
        userId: Int,
        childProfile: ChildProfileSync?,
        healthLogs: [HealthLogEntry]?,
        savedMeals: [SavedMealEstimate]? = nil,
        nutrientDailyUsage: NutrientDailyUsage? = nil
    ) async throws {
        let body = ParentAppDataSyncRequest(
            userId: userId,
            childProfile: childProfile,
            healthLogs: healthLogs,
            savedMeals: savedMeals,
            nutrientDailyUsage: nutrientDailyUsage
        )
        let _: MessageResponse = try await post("/api/app-data", body: body)
    }

    func loadAppData(userId: Int) async throws -> ParentAppDataSnapshot {
        try await post("/api/app-data/load", body: AppSessionRequest(userId: userId))
    }

    func appSettings(userId: Int) async throws -> ParentAppSettings {
        try await post("/api/app-settings", body: AppSessionRequest(userId: userId))
    }

    func healthInsights(
        childName: String,
        quickLogTitles: [String],
        snapshotTitles: [String],
        logs: [HealthLogEntry],
        language: String
    ) async throws -> [HealthInsight] {
        let body = HealthInsightsRequest(
            childName: childName,
            quickLogTitles: quickLogTitles,
            snapshotTitles: snapshotTitles,
            logs: logs,
            language: language
        )
        let response: HealthInsightsResponse = try await post("/api/health-insights", body: body)
        return response.insights
    }

    private func post<Request: Encodable, Response: Decodable>(_ path: String, body: Request) async throws -> Response {
        guard let url = baseURL?.appending(path: path) else {
            throw AuthAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AppSessionToken.value {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthAPIError.invalidResponse
        }

        if (200..<300).contains(httpResponse.statusCode) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(Response.self, from: data)
        }

        if let errorBody = try? JSONDecoder().decode(MessageResponse.self, from: data) {
            throw AuthAPIError.server(errorBody.message)
        }

        throw AuthAPIError.server(String(format: localizedAppString("Request failed with status %@"), "\(httpResponse.statusCode)"))
    }
}

struct NutritionAPI {
    var baseURL = APIConfig.baseURL

    func analyzeMeal(imageData: String, language: String) async throws -> MealNutritionEstimate {
        guard let url = baseURL?.appending(path: "/api/analyze-meal") else {
            throw AuthAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AppSessionToken.value {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONEncoder().encode(MealAnalysisRequest(imageData: imageData, language: language, aiConsent: true))

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

        throw AuthAPIError.server(String(format: localizedAppString("Meal analysis failed with status %@"), "\(httpResponse.statusCode)"))
    }
}

private struct MealAnalysisRequest: Encodable {
    let imageData: String
    let language: String
    let aiConsent: Bool
}

struct ChildProfileSync: Codable {
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
    let savedMeals: [SavedMealEstimate]?
    let nutrientDailyUsage: NutrientDailyUsage?
}

struct ParentAppSettings: Decodable {
    let nutrientDailyLimit: Int
}

struct ParentAppDataSnapshot: Decodable {
    let childProfile: ChildProfileSync?
    let healthLogs: [HealthLogEntry]
    let savedMeals: [SavedMealEstimate]
    let nutrientDailyUsage: NutrientDailyUsage?
    let nutrientDailyLimit: Int
}

private struct HealthInsightsRequest: Encodable {
    let childName: String
    let quickLogTitles: [String]
    let snapshotTitles: [String]
    let logs: [HealthLogEntry]
    let language: String
}

private struct AppSessionRequest: Encodable {
    let userId: Int
}

private struct ChangePasswordRequest: Encodable {
    let userId: Int
    let currentPassword: String
    let newPassword: String
}

private struct HealthInsightsResponse: Decodable {
    let insights: [HealthInsight]
}

struct HealthInsight: Codable, Identifiable, Equatable {
    let id: UUID
    let title: String
    let message: String

    init(id: UUID = UUID(), title: String, message: String) {
        self.id = id
        self.title = title
        self.message = message
    }

    private enum CodingKeys: String, CodingKey {
        case title
        case message
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.title = try container.decode(String.self, forKey: .title)
        self.message = try container.decode(String.self, forKey: .message)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(message, forKey: .message)
    }
}
