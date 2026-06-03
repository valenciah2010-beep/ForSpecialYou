import SwiftUI

struct AuthRootView: View {
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                if let user = viewModel.currentUser {
                    WelcomeView(user: user, logout: viewModel.logout)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            HeaderView()

                            Picker("", selection: $viewModel.screen) {
                                Text("Log In").tag(AuthViewModel.Screen.login)
                                Text("Sign Up").tag(AuthViewModel.Screen.signup)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)

                            Group {
                                switch viewModel.screen {
                                case .login:
                                    LoginView(viewModel: viewModel)
                                case .signup:
                                    SignupView(viewModel: viewModel)
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 28)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: viewModel.screen)
            .animation(.easeInOut(duration: 0.2), value: viewModel.currentUser?.id)
        }
    }
}

struct HeaderView: View {
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppTheme.accent)
                    .frame(width: 56, height: 56)

                Text("CP")
                    .font(.title3.weight(.black))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 6) {
                Text("Care Portal")
                    .font(.largeTitle.weight(.bold))
            }
        }
        .padding(.top, 8)
    }
}
