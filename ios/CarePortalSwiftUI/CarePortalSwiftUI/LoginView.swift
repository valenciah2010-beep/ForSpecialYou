import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Button {
                viewModel.showHome()
            } label: {
                Label("Home", systemImage: "chevron.left")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.accent)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                Text("Welcome Back")
                    .font(.title2.weight(.bold))
            }

            AuthTextField(title: "Parent Username", text: $viewModel.loginNickname, contentType: .username)

            AuthSecureField(title: "Password", text: $viewModel.loginPassword, contentType: .password)

            MessageBanner(message: viewModel.message, isError: viewModel.isError)

            Button {
                Task { await viewModel.login() }
            } label: {
                ButtonLabel(title: viewModel.isLoading ? "Logging In..." : "Log In")
            }
            .disabled(viewModel.isLoading)

            Button("Need an account? Sign up") {
                viewModel.showSignup()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.accent)
            .frame(maxWidth: .infinity)
        }
        .authPanel()
    }
}
