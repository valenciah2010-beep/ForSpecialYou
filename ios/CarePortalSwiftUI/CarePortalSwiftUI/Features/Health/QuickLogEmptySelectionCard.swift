import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct QuickLogEmptySelectionCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: "slider.horizontal.3")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 42, height: 42)
                    .background(AppTheme.accent.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text(localizedAppString("No quick-log buttons selected"))
                        .font(.headline.weight(.black))
                        .foregroundStyle(AppTheme.text)

                    Text(localizedAppString("Tap the slider icon in the top right to choose quick-log buttons."))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.panel)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(localizedAppString("Choose quick-log buttons"))
    }
}

