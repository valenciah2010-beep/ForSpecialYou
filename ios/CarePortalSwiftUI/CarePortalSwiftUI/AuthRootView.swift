import SwiftUI
import UIKit

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
                            Group {
                                switch viewModel.screen {
                                case .home:
                                    AuthHomeView(viewModel: viewModel)
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
            .task(id: viewModel.currentUser?.id) {
                await viewModel.validateSavedSession()
            }
        }
    }
}

struct HeaderView: View {
    var body: some View {
        VStack(spacing: 10) {
            CarePortalLogo(size: 118)

            VStack(spacing: 6) {
                Text("Care Portal")
                    .font(.largeTitle.weight(.bold))
            }
        }
        .padding(.top, 8)
    }
}

struct AuthHomeView: View {
    @ObservedObject var viewModel: AuthViewModel
    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.english.rawValue
    @State private var isShowingLanguagePicker = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button {
                isShowingLanguagePicker = true
            } label: {
                Image(systemName: "globe")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 42, height: 42)
                    .background(AppTheme.accent.opacity(0.12))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Language")

            VStack(spacing: 24) {
                Spacer(minLength: 12)

                HeaderView()

                VStack(spacing: 10) {
                    Text("For Special You")
                        .font(.title.weight(.bold))
                        .foregroundStyle(AppTheme.text)

                    Text("A parent-run care space for tracking your child's health, routines, and support needs.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }

                VStack(spacing: 12) {
                    Button {
                        viewModel.showLogin()
                    } label: {
                        ButtonLabel(title: "Log In")
                    }

                    Button {
                        viewModel.showSignup()
                    } label: {
                        Text("Create Parent Account")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.accent)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.accent.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }

                Spacer(minLength: 12)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: AuthLayout.tallPanelMinHeight)
        .authPanel()
        .confirmationDialog("Language", isPresented: $isShowingLanguagePicker, titleVisibility: .visible) {
            Button("English") {
                languageCode = AppLanguage.english.rawValue
            }

            Button("中文") {
                languageCode = AppLanguage.chinese.rawValue
            }
        }
    }
}

struct CarePortalLogo: View {
    let size: CGFloat

    var body: some View {
        Group {
            if let image = logoImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "heart.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color(red: 1.0, green: 0.18, blue: 0.2))
            }
        }
        .frame(width: size, height: size)
        .shadow(color: Color(red: 1.0, green: 0.18, blue: 0.2).opacity(0.16), radius: 12, x: 0, y: 6)
        .accessibilityLabel("For Special You logo")
    }

    private var logoImage: UIImage? {
        if let image = UIImage(named: "CarePortalLogo") ?? UIImage(named: "CarePortalLogo.png") {
            return image
        }

        guard let url = Bundle.main.url(forResource: "CarePortalLogo", withExtension: "png"),
              let data = try? Data(contentsOf: url) else {
            return nil
        }

        return UIImage(data: data)
    }
}
