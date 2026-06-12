import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var isShowingTerms = false
    @State private var hasAgreedToTerms = false

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

            AuthTextField(title: "Parent Username", text: $viewModel.loginNickname)

            AuthSecureField(
                title: "Password",
                text: $viewModel.loginPassword,
                contentType: .password,
                isDisabled: viewModel.isCaptchaRequired
            )

            if viewModel.isCaptchaRequired {
                CaptchaChallengeView(
                    code: viewModel.captchaCode,
                    input: $viewModel.captchaInput,
                    refresh: viewModel.refreshCaptcha
                )
            }

            MessageBanner(message: viewModel.message, isError: viewModel.isError)

            TermsAgreementToggle(
                isAgreed: $hasAgreedToTerms,
                showTerms: { isShowingTerms = true }
            )

            Button {
                if viewModel.isCaptchaRequired {
                    viewModel.completeCaptchaChallenge()
                } else {
                    Task { await viewModel.login() }
                }
            } label: {
                ButtonLabel(title: loginButtonTitle)
                    .opacity(hasAgreedToTerms ? 1 : 0.45)
            }
            .disabled(viewModel.isLoading || !hasAgreedToTerms)

            Button("Need an account? Sign up") {
                viewModel.showSignup()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.accent)
            .frame(maxWidth: .infinity)
        }
        .authPanel(minHeight: AuthLayout.tallPanelMinHeight, alignment: .topLeading)
        .sheet(isPresented: $isShowingTerms) {
            TermsDetailsSheet()
        }
    }

    private var loginButtonTitle: String {
        if viewModel.isLoading {
            return "Logging In..."
        }

        return viewModel.isCaptchaRequired ? "Verify Code" : "Log In"
    }
}

struct CaptchaChallengeView: View {
    let code: String
    @Binding var input: String
    let refresh: () -> Void

    var body: some View {
        HStack(spacing: 7) {
            Text("Code")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.text)
                .lineLimit(1)
                .frame(width: 48, alignment: .leading)

            CaptchaImageView(code: code)

            TextField("Code", text: $input)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 32)
                .padding(.horizontal, 6)
                .background(AppTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

            Button {
                input = ""
                refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.caption.weight(.black))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 32, height: 32)
                    .background(AppTheme.accent.opacity(0.12))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Refresh verification code")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(AppTheme.accent.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct CaptchaImageView: View {
    let code: String

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(code.enumerated()), id: \.offset) { index, character in
                Text(String(character))
                    .font(.subheadline.weight(.black).monospaced())
                    .foregroundStyle(AppTheme.text)
                    .rotationEffect(.degrees(index.isMultiple(of: 2) ? -7 : 6))
                    .offset(y: index.isMultiple(of: 2) ? -1 : 1)
            }
        }
        .frame(width: 90, height: 32)
        .background(
            ZStack {
                AppTheme.fieldBackground

                ForEach(0..<4, id: \.self) { index in
                    Rectangle()
                        .fill(AppTheme.accent.opacity(0.16))
                        .frame(height: 1)
                        .rotationEffect(.degrees(index.isMultiple(of: 2) ? -12 : 13))
                        .offset(y: CGFloat(index * 5 - 8))
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(AppTheme.accent.opacity(0.18), lineWidth: 1)
        }
        .accessibilityLabel("Verification code")
    }
}
