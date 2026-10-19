import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct MedicationFormMenu: View {
    let title: String
    let value: String
    let options: [String]
    let onSelect: (String) -> Void

    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(localizedAppString(option)) {
                    onSelect(option)
                }
            }
        } label: {
            HStack {
                Text(value.isEmpty ? localizedAppString(title) : localizedAppString(value))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(MedicationFormStyle.background)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(MedicationFormStyle.border.opacity(0.55), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

