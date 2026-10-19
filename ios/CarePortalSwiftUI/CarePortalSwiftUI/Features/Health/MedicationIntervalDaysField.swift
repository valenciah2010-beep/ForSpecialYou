import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct MedicationIntervalDaysField: View {
    @Binding var days: String

    var body: some View {
        HStack(spacing: 12) {
            Text(localizedAppString("Every how many days?"))
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppTheme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer()

            TextField("2", text: $days)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.text)
                .frame(width: 58)
                .padding(.vertical, 8)
                .background(Color(red: 0.96, green: 0.98, blue: 0.97))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text(localizedAppString("days"))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(MedicationFormStyle.detailBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(MedicationFormStyle.border.opacity(0.55), lineWidth: 1)
        }
    }
}

