import SwiftUI

struct SignupView: View {
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
                Text("Create Parent Account")
                    .font(.title2.weight(.bold))

                Text("Set up a parent login to track your child's care.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            AuthTextField(title: "Parent Username", text: $viewModel.signupNickname)
            AuthTextField(title: "Email", text: $viewModel.signupEmail, keyboard: .emailAddress, contentType: .emailAddress)

            AuthSecureField(title: "Password", text: $viewModel.signupPassword, contentType: .newPassword)
            AuthSecureField(title: "Verify Password", text: $viewModel.signupVerifyPassword, contentType: .newPassword)

            MessageBanner(message: viewModel.message, isError: viewModel.isError)

            Button {
                Task { await viewModel.signup() }
            } label: {
                ButtonLabel(title: viewModel.isLoading ? "Creating Account..." : "Create Parent Account")
            }
            .disabled(viewModel.isLoading)

            Button("Already have an account? Log in") {
                viewModel.showLogin()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.accent)
            .frame(maxWidth: .infinity)
        }
        .authPanel()
    }
}
