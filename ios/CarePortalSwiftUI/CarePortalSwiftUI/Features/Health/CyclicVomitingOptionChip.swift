import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct CyclicVomitingOptionChip: View {
    let title: String
    let isSelected: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(isSelected ? .white : .secondary.opacity(0.7))
                Text(localizedAppString(title))
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(isSelected ? .white : AppTheme.text)
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(isSelected ? tint : AppTheme.fieldBackground)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

