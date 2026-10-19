import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct MedicationFormTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var showsClearButton: Bool
    var background: Color = AppTheme.panel

    var body: some View {
        HStack(spacing: 8) {
            TextField(localizedAppString(placeholder), text: $text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.never)
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppTheme.text)

            if showsClearButton && !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(MedicationFormStyle.border.opacity(0.55), lineWidth: 1)
        }
    }
}

