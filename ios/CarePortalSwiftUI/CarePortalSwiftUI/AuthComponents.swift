import SwiftUI

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
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.text)

            TextField(title, text: $text)
                .keyboardType(keyboard)
                .textContentType(contentType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.text)

            SecureField(title, text: $text)
                .textContentType(contentType)
                .padding(14)
                .background(AppTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

struct ButtonLabel: View {
    let title: String

    var body: some View {
        Text(title)
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

extension View {
    func authPanel() -> some View {
        self
            .padding(20)
            .background(AppTheme.panel)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
    }
}

