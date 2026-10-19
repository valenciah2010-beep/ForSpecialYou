import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct StoolTypePickerCard: View {
    let type: Int
    let isSelected: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                BristolStoolIcon(type: type)
                    .frame(width: 92, height: 58)

                Text("\(localizedAppString("Type")) \(type)")
                    .font(.caption.weight(.black))
                    .foregroundStyle(AppTheme.text)

                Text(localizedAppString(BristolStoolGuide.group(for: type)))
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(10)
            .frame(width: 120, height: 132)
            .background(isSelected ? tint.opacity(0.18) : AppTheme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? tint : Color.clear, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
    }
}

