import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct MedicineHistoryDayCard: View {
    let day: MedicineHistoryDay
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "pills.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(tint)
                    .frame(width: 42, height: 42)
                    .background(tint.opacity(0.15))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(day.dateTitle)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.text)

                    Text(String(format: localizedAppString("Last saved %@"), day.savedTimeText))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            VStack(spacing: 8) {
                ForEach(day.items) { item in
                    HStack(spacing: 10) {
                        Image(systemName: "pills.fill")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(tint)
                            .frame(width: 24)

                        Text(localizedMedicineDoseText(item.name))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(AppTheme.text)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(item.timeText)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(11)
                    .background(AppTheme.fieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
    }
}

