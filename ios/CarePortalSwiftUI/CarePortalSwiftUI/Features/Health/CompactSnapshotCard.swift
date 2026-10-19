import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct CompactSnapshotCard: View {
    let option: SnapshotOption
    var displayValue: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: option.icon)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(option.tint)
                    .frame(width: 34, height: 34)
                    .background(option.tint.opacity(0.12))
                    .clipShape(Circle())

                Text(LocalizedStringKey(option.title))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.text)

                Spacer(minLength: 6)

                if let displayValue, !displayValue.isEmpty, displayValue != "--" {
                    Text(displayValue)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(AppTheme.panel)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(option.tint.opacity(0.16), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

