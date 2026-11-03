import SwiftUI
import UIKit

struct AuthRootView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                if let user = viewModel.currentUser, viewModel.shouldShowFirstLoginOnboarding {
                    FirstLoginOnboardingView(user: user) { childName, age, gender, diagnoses in
                        viewModel.completeFirstLoginOnboarding(
                            childName: childName,
                            age: age,
                            gender: gender,
                            diagnoses: diagnoses
                        )
                    }
                } else if let user = viewModel.currentUser {
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
        }
    }
}

private struct FirstLoginOnboardingView: View {
    let user: CarePortalUser
    let finish: (String, String, String, String) -> Void

    @State private var slide = 0
    @State private var childName = ""
    @State private var childAge = ""
    @State private var gender = "Prefer not to say"
    @State private var diagnoses = ""
    @State private var acceptsTerms = false
    @State private var showsTerms = false

    var body: some View {
        VStack(spacing: 0) {
            progress
                .padding(.horizontal, 28)
                .padding(.top, 20)

            Group {
                switch slide {
                case 0:
                    welcomeSlide
                case 1:
                    childDetailsSlide
                default:
                    termsSlide
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Button(action: advance) {
                Text(slide == 2 ? "Start Using For Special You" : "Next")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.panel)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(canAdvance ? AppTheme.accent : AppTheme.accent.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(!canAdvance)
            .padding(20)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .sheet(isPresented: $showsTerms) {
            TermsDetailsSheet()
        }
    }

    private var progress: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { step in
                Capsule()
                    .fill(step <= slide ? AppTheme.accent : AppTheme.accent.opacity(0.18))
                    .frame(height: 5)
            }
        }
    }

    private var welcomeSlide: some View {
        VStack(spacing: 18) {
            Spacer()
            CarePortalLogo(size: 132)
            Text("For Special You")
                .font(.largeTitle.weight(.black))
                .foregroundStyle(AppTheme.text)
            Text("For Special You is created for parents or caretakers of special needs children with developmental delays to easily track their symptoms, daily life, milestones, therapy, and more. We aim to empower our children through navigable systems that log and support their unique needs.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 30)
            Spacer()
        }
    }

    private var childDetailsSlide: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(AppTheme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)
                Text("Let's get to know your child")
                    .font(.title.weight(.bold))
                    .frame(maxWidth: .infinity, alignment: .center)
                Text("Tell us a little about them")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                onboardingField(title: "What's your child's name?", text: $childName, placeholder: "Enter your child's name")
                onboardingField(title: "How old is your child?", text: $childAge, placeholder: "Enter age", keyboard: .numberPad)
                Text("Gender")
                    .font(.headline.weight(.bold))
                Picker("Gender", selection: $gender) {
                    Text("Prefer not to say").tag("Prefer not to say")
                    Text("Female").tag("Female")
                    Text("Male").tag("Male")
                    Text("Nonbinary").tag("Nonbinary")
                    Text("Self-describe").tag("Self-describe")
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .frame(height: 52)
                .background(AppTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                onboardingField(title: "Diagnosis or Conditions", text: $diagnoses, placeholder: "Add diagnoses or conditions (optional)")
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 18)
        }
    }

    private var termsSlide: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(AppTheme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)
                Text("Terms and Conditions")
                    .font(.title.weight(.bold))
                    .frame(maxWidth: .infinity, alignment: .center)
                Text("For Special You helps caregivers organize information. It does not provide medical advice, diagnosis, or treatment. AI-generated information may be incomplete or inaccurate and should not be used for important health decisions without a qualified professional.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .padding(16)
                    .background(AppTheme.panel)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                Button("Read the full Terms and Conditions") {
                    showsTerms = true
                }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.accent)
                TermsAgreementToggle(isAgreed: $acceptsTerms, showTerms: { showsTerms = true })
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 18)
        }
    }

    private var canAdvance: Bool {
        switch slide {
        case 1:
            return !childName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !childAge.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 2:
            return acceptsTerms
        default:
            return true
        }
    }

    private func onboardingField(title: String, text: Binding<String>, placeholder: String, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline.weight(.bold))
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(.words)
                .padding(.horizontal, 14)
                .frame(height: 52)
                .background(AppTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func advance() {
        if slide < 2 {
            withAnimation(.easeInOut(duration: 0.2)) { slide += 1 }
        } else {
            finish(childName, childAge, gender, diagnoses)
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
