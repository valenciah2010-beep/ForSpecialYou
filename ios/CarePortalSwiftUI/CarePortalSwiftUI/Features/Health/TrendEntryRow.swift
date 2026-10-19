import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct TrendEntryRow: View {
    let entry: HealthLogEntry

    var body: some View {
        HStack(spacing: 10) {
            Text("\(entry.severity)/5")
                .font(.caption.weight(.black))
                .foregroundStyle(.white)
                .frame(width: 42, height: 28)
                .background(AppTheme.accent)
                .clipShape(Capsule())

            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(entry.title))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.text)

                Text(entry.timestamp, style: .time)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !entry.value.isEmpty {
                Text(entry.value)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(10)
        .background(AppTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

