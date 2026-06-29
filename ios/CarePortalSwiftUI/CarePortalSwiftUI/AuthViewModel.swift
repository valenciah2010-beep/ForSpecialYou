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
    @Published var failedLoginAttempts = 0
    @Published var isCaptchaRequired = false
    @Published var captchaCode = AuthViewModel.makeCaptchaCode()
    @Published var captchaInput = ""

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

        if isCaptchaRequired {
            showError(localizedAppString("Please complete the verification code before entering your password again."))
            return
        }

        guard !loginNickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !loginPassword.isEmpty else {
            showError(localizedAppString("Please enter your parent username and password."))
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let user = try await api.login(username: loginNickname, password: loginPassword)
            await restoreServerAppData(for: user)
            currentUser = user
            saveUser(user)
            loginPassword = ""
            resetLoginProtection()
        } catch {
            if isInvalidCredentialError(error) {
                failedLoginAttempts += 1

                if failedLoginAttempts >= 2 {
                    isCaptchaRequired = true
                    refreshCaptcha()
                    captchaInput = ""
                    showError(localizedAppString("Too many incorrect attempts. Please complete the verification code."))
                } else {
                    showError(error.localizedDescription)
                }
            } else {
                showError(error.localizedDescription)
            }
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
            await restoreServerAppData(for: user)
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
        resetLoginProtection()
        screen = .home
        clearMessage()
    }

    func refreshCaptcha() {
        captchaCode = Self.makeCaptchaCode()
    }

    func completeCaptchaChallenge() {
        clearMessage()
        let enteredCode = captchaInput.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard enteredCode == captchaCode else {
            captchaInput = ""
            refreshCaptcha()
            showError(localizedAppString("Please enter the verification code shown."))
            return
        }

        isCaptchaRequired = false
        failedLoginAttempts = 0
        captchaInput = ""
        loginPassword = ""
        message = localizedAppString("Verification complete. Please enter your password again.")
        isError = false
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

    private func restoreServerAppData(for user: CarePortalUser) async {
        do {
            let snapshot = try await api.loadAppData(userId: user.id)
            restoreChildProfile(snapshot.childProfile, userID: user.id)
            restoreHealthLogs(snapshot.healthLogs, userID: user.id)
            restoreSavedMeals(snapshot.savedMeals, userID: user.id)
            restoreNutrientDailyUsage(snapshot.nutrientDailyUsage, userID: user.id)
            UserDefaults.standard.set(snapshot.nutrientDailyLimit, forKey: "nutrient.\(user.id).dailyEstimateLimit")
        } catch {
            print("App data restore failed: \(error.localizedDescription)")
        }
    }

    private func restoreChildProfile(_ profile: ChildProfileSync?, userID: Int) {
        guard let profile else { return }
        setStringIfLocalBlank(profile.fullName, key: "profile.\(userID).fullName")
        setStringIfLocalBlank(profile.birthDate, key: "profile.\(userID).birthDate")
        setStringIfLocalBlank(profile.supportNeeds, key: "profile.\(userID).phone")
        setStringIfLocalBlank(profile.homeSchoolNotes, key: "profile.\(userID).address")
        setStringIfLocalBlank(profile.emergencyContact, key: "profile.\(userID).emergencyContact")
        setStringIfLocalBlank(profile.careNotes, key: "profile.\(userID).medicalNotes")
    }

    private func restoreHealthLogs(_ logs: [HealthLogEntry], userID: Int) {
        guard !logs.isEmpty else { return }
        let key = "health.\(userID).logData"
        guard (UserDefaults.standard.data(forKey: key) ?? Data()).isEmpty,
              let data = try? JSONEncoder().encode(logs) else {
            return
        }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func restoreSavedMeals(_ meals: [SavedMealEstimate], userID: Int) {
        guard !meals.isEmpty else { return }
        let key = "nutrient.\(userID).savedMealHistoryData"
        guard (UserDefaults.standard.data(forKey: key) ?? Data()).isEmpty,
              let data = try? JSONEncoder().encode(meals) else {
            return
        }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func restoreNutrientDailyUsage(_ usage: NutrientDailyUsage?, userID: Int) {
        guard let usage else { return }
        let key = "nutrient.\(userID).dailyUsageData"
        guard (UserDefaults.standard.data(forKey: key) ?? Data()).isEmpty,
              let data = try? JSONEncoder().encode(usage) else {
            return
        }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func setStringIfLocalBlank(_ value: String, key: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let existing = UserDefaults.standard.string(forKey: key) ?? ""
        guard existing.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        UserDefaults.standard.set(value, forKey: key)
    }

    private func resetLoginProtection() {
        failedLoginAttempts = 0
        isCaptchaRequired = false
        captchaInput = ""
        refreshCaptcha()
    }

    private func isInvalidCredentialError(_ error: Error) -> Bool {
        guard case AuthAPIError.server(let message) = error else {
            return false
        }

        return message.localizedCaseInsensitiveContains("invalid")
            && (message.localizedCaseInsensitiveContains("password")
                || message.localizedCaseInsensitiveContains("nickname")
                || message.localizedCaseInsensitiveContains("username"))
    }

    private static func makeCaptchaCode() -> String {
        let characters = Array("23456789ABCDEFGHJKLMNPQRSTUVWXYZ")
        return String((0..<4).compactMap { _ in characters.randomElement() })
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
