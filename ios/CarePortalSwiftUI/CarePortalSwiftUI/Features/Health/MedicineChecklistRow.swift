import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct MedicineChecklistRow: View {
    let row: MedicationChecklistItem
    let isChecked: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isChecked ? tint : .secondary)

                Text(row.timeText)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(tint)
                    .frame(width: 72, alignment: .leading)

                VStack(alignment: .leading, spacing: 3) {
                    Text(row.medication.displayName.isEmpty ? localizedAppString("Unnamed Medicine") : row.medication.displayName)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppTheme.text)

                    if !row.dose.isEmpty {
                        Text(localizedMedicineDoseText(row.dose))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
            .padding(12)
            .background(AppTheme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

