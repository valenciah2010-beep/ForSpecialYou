import SwiftUI
import UIKit

enum AppTheme {
    static let accent = Color(red: 0.15, green: 0.41, blue: 0.36)
    static let background = Color(red: 0.95, green: 0.97, blue: 0.95)
    static let panel = Color.white
    static let fieldBackground = Color(red: 0.97, green: 0.98, blue: 0.97)
    static let text = Color(red: 0.09, green: 0.13, blue: 0.11)
}

struct AuthTextField: View {
    let title: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var contentType: UITextContentType?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringKey(title))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.text)

            TextField(LocalizedStringKey(title), text: $text)
                .keyboardType(keyboard)
                .textContentType(contentType)
                .textInputAutocapitalization(.never)
                .padding(14)
                .background(AppTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

struct AuthSecureField: View {
    let title: String
    @Binding var text: String
    var contentType: UITextContentType?
    var isDisabled = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringKey(title))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.text)

            SecureField(LocalizedStringKey(title), text: $text)
                .textContentType(contentType)
                .disabled(isDisabled)
                .padding(14)
                .background(AppTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .opacity(isDisabled ? 0.45 : 1)
        }
    }
}

struct ButtonLabel: View {
    let title: String

    var body: some View {
        Text(LocalizedStringKey(title))
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.accent)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct MessageBanner: View {
    let message: String
    let isError: Bool

    var body: some View {
        if !message.isEmpty {
            Text(message)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isError ? Color.red : AppTheme.accent)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background((isError ? Color.red : AppTheme.accent).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

struct TermsDetailsSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Terms and Conditions")
                        .font(.title2.weight(.black))
                        .foregroundStyle(AppTheme.text)

                    Text("TermsIntro")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)

                    termsSection(title: "Privacy and care data", body: "TermsPrivacyBody")
                    termsSection(title: "Parent responsibility", body: "TermsParentBody")
                    termsSection(title: "Not medical advice", body: "TermsMedicalBody")
                    termsSection(title: "Emergency use", body: "TermsEmergencyBody")
                }
                .padding(20)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.accent)
                }
            }
        }
        .presentationDetents([.large])
    }

    private func termsSection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedStringKey(title))
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.text)

            Text(LocalizedStringKey(body))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct TermsAgreementToggle: View {
    @Binding var isAgreed: Bool
    let showTerms: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button {
                isAgreed.toggle()
            } label: {
                Image(systemName: isAgreed ? "checkmark.square.fill" : "square")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isAgreed ? AppTheme.accent : .secondary.opacity(0.7))
                    .frame(width: 24)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text("I agree to the")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Button {
                        showTerms()
                    } label: {
                        Text("Terms and Conditions")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.accent)
                            .underline()
                    }
                    .buttonStyle(.plain)
                }

                Text("before using this app.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(AppTheme.fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityLabel("Terms and Conditions agreement")
        .accessibilityValue(isAgreed ? "Agreed" : "Not agreed")
    }
}

extension View {
    func authPanel(minHeight: CGFloat? = nil, alignment: Alignment = .center) -> some View {
        self
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: alignment)
            .padding(20)
            .background(AppTheme.panel)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
    }
}

enum AuthLayout {
    static var tallPanelMinHeight: CGFloat {
        max(560, UIScreen.main.bounds.height - 170)
    }
}
