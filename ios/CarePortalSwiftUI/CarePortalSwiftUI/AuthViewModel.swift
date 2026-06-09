import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    enum Screen {
        case home
        case login
        case signup
    }

    @Published var screen: Screen = .home
    @Published var loginNickname = ""
    @Published var loginPassword = ""
    @Published var signupNickname = ""
    @Published var signupEmail = ""
    @Published var signupPassword = ""
    @Published var signupVerifyPassword = ""
    @Published var message = ""
    @Published var isError = false
    @Published var isLoading = false
    @Published var currentUser: CarePortalUser?

    private static let savedUserKey = "auth.savedCarePortalUser"
    private let api = AuthAPI()

    init() {
        currentUser = Self.loadSavedUser()
    }

    func showHome() {
        screen = .home
        clearMessage()
    }

    func showLogin() {
        screen = .login
        clearMessage()
    }

    func showSignup() {
        screen = .signup
        clearMessage()
    }

    func login() async {
        clearMessage()

        guard !loginNickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !loginPassword.isEmpty else {
            showError(localizedAppString("Please enter your parent username and password."))
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let user = try await api.login(username: loginNickname, password: loginPassword)
            currentUser = user
            saveUser(user)
            loginPassword = ""
        } catch {
            showError(error.localizedDescription)
        }
    }

    func signup() async {
        clearMessage()

        let nickname = signupNickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = signupEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard !nickname.isEmpty, !email.isEmpty, !signupPassword.isEmpty, !signupVerifyPassword.isEmpty else {
            showError(localizedAppString("Please fill out every field."))
            return
        }

        guard email.contains("@"), email.contains(".") else {
            showError(localizedAppString("Please enter a valid email address."))
            return
        }

        guard signupPassword.count >= 6, signupPassword.contains(where: { $0.isNumber }) else {
            showError(localizedAppString("Password must be at least 6 characters and include one number."))
            return
        }

        guard signupPassword == signupVerifyPassword else {
            showError(localizedAppString("Passwords do not match."))
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            message = try await api.signup(
                nickname: nickname,
                email: email,
                password: signupPassword,
                verifyPassword: signupVerifyPassword
            )
            isError = false
            loginNickname = nickname
            signupNickname = ""
            signupEmail = ""
            signupPassword = ""
            signupVerifyPassword = ""
            screen = .login
        } catch {
            showError(error.localizedDescription)
        }
    }

    func validateSavedSession() async {
        guard let savedUser = currentUser else { return }

        do {
            let user = try await api.validateSavedSession(userId: savedUser.id)
            currentUser = user
            saveUser(user)
        } catch {
            if case AuthAPIError.server(let message) = error,
                message.localizedCaseInsensitiveContains("blocked")
                    || message.localizedCaseInsensitiveContains("log in again") {
                logout()
                showError(localizedServerMessage(message))
                screen = .login
            } else {
                print("Saved session validation failed: \(error.localizedDescription)")
            }
        }
    }

    func logout() {
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: Self.savedUserKey)
        loginNickname = ""
        loginPassword = ""
        screen = .home
        clearMessage()
    }

    private static func loadSavedUser() -> CarePortalUser? {
        guard let data = UserDefaults.standard.data(forKey: savedUserKey) else { return nil }

        do {
            return try JSONDecoder().decode(CarePortalUser.self, from: data)
        } catch {
            UserDefaults.standard.removeObject(forKey: savedUserKey)
            return nil
        }
    }

    private func saveUser(_ user: CarePortalUser) {
        guard let data = try? JSONEncoder().encode(user) else { return }
        UserDefaults.standard.set(data, forKey: Self.savedUserKey)
    }

    private func clearMessage() {
        message = ""
        isError = false
    }

    private func showError(_ text: String) {
        message = text
        isError = true
    }
}
