import Foundation

struct CarePortalUser: Codable, Identifiable {
    let id: Int
    let nickname: String
    let email: String
    let role: String
    let profileImage: String?
}

struct LoginRequest: Encodable {
    let username: String
    let password: String
}

struct SignupRequest: Encodable {
    let nickname: String
    let username: String
    let email: String
    let password: String
    let verifyPassword: String
    let role: String
}

struct AuthResponse: Decodable {
    let message: String
    let user: CarePortalUser?
}

struct MessageResponse: Decodable {
    let message: String
}
