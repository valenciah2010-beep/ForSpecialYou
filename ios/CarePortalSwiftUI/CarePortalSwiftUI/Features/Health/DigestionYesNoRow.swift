import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct DigestionYesNoRow: View {
    let title: String
    @Binding var value: Bool?
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localizedAppString(title))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.text)

            HStack(spacing: 10) {
                yesNoButton(title: "Yes", option: true)
                yesNoButton(title: "No", option: false)
            }
        }
    }

    private func yesNoButton(title: String, option: Bool) -> some View {
        Button {
            value = value == option ? nil : option
        } label: {
            Text(localizedAppString(title))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(value == option ? .white : AppTheme.text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(value == option ? tint : AppTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

