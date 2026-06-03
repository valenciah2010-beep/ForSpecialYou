import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    enum Screen {
        case login
        case signup
    }

    @Published var screen: Screen = .login
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

    private let api = AuthAPI()

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
            showError("Please enter your parent username and password.")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            currentUser = try await api.login(username: loginNickname, password: loginPassword)
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
            showError("Please fill out every field.")
            return
        }

        guard email.contains("@"), email.contains(".") else {
            showError("Please enter a valid email address.")
            return
        }

        guard signupPassword.count >= 6, signupPassword.contains(where: { $0.isNumber }) else {
            showError("Password must be at least 6 characters and include one number.")
            return
        }

        guard signupPassword == signupVerifyPassword else {
            showError("Passwords do not match.")
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

    func logout() {
        currentUser = nil
        loginNickname = ""
        loginPassword = ""
        screen = .login
        clearMessage()
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
