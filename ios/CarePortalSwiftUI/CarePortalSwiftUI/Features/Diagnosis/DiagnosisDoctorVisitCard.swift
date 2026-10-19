import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct DiagnosisDoctorVisitCard: View {
    let visit: DiagnosisDoctorVisit

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(visit.categoryText)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .lineLimit(2)

            Text(visit.displayTitle)
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.text)
                .lineLimit(2)

            HStack(spacing: 8) {
                Text(localizedDateString(visit.date, dateStyle: .medium, timeStyle: .none))

                if !visit.clinicLocation.isEmpty {
                    Text("•")
                    Text(visit.clinicLocation)
                        .lineLimit(1)
                }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)

            if !visit.attachments.isEmpty {
                Text(String(format: localizedAppString("%d attachment(s)"), visit.attachments.count))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

