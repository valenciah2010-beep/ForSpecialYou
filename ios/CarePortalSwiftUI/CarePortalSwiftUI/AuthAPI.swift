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

        guard let token = response.token else { throw AuthAPIError.invalidResponse }
        SessionStore.token = token
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
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if path == "/api/health-insights" { try await APITransport.confirmAI() }
        return try await APITransport.send(path, body: encoder.encode(body))
    }
}

struct NutritionAPI {
    var baseURL = APIConfig.baseURL

    func analyzeMeal(imageData: String, language: String) async throws -> MealNutritionEstimate {
        try await APITransport.confirmAI()
        let raw = imageData.components(separatedBy: ",").last ?? imageData
        guard let data = Data(base64Encoded: raw) else { throw AuthAPIError.invalidResponse }
        let imageID = try await APITransport.upload(data)
        let body = try JSONSerialization.data(withJSONObject: ["imageId": imageID, "language": language])
        return try await APITransport.send("/api/analyze-meal", body: body)
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

extension ChildProfileSync {
    // New accounts and legacy snapshots can contain an empty or partial profile.
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        fullName = try values.decodeIfPresent(String.self, forKey: .fullName) ?? ""
        birthDate = try values.decodeIfPresent(String.self, forKey: .birthDate) ?? ""
        supportNeeds = try values.decodeIfPresent(String.self, forKey: .supportNeeds) ?? ""
        homeSchoolNotes = try values.decodeIfPresent(String.self, forKey: .homeSchoolNotes) ?? ""
        emergencyContact = try values.decodeIfPresent(String.self, forKey: .emergencyContact) ?? ""
        careNotes = try values.decodeIfPresent(String.self, forKey: .careNotes) ?? ""
    }
}

private struct ParentAppDataSyncRequest: Encodable {
    let userId: Int
    let childProfile: ChildProfileSync?
    let healthLogs: [HealthLogEntry]?
    let savedMeals: [SavedMealEstimate]?
    let nutrientDailyUsage: NutrientDailyUsage?
}

struct ParentAppSettings: Decodable {
    let nutrientDailyUsage: NutrientDailyUsage?
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
