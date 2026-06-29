import Foundation

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

        guard let user = response.user else {
            throw AuthAPIError.invalidResponse
        }

        return user
    }

    func validateSavedSession(userId: Int) async throws -> CarePortalUser {
        let response: AuthResponse = try await post("/api/app-session", body: AppSessionRequest(userId: userId))

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
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(MealAnalysisRequest(imageData: imageData, language: language))

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
