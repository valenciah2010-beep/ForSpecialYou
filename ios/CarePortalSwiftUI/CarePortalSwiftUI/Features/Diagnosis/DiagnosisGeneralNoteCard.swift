import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct DiagnosisGeneralNoteCard: View {
    let note: DiagnosisGeneralNote

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Text(note.categoryText)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .lineLimit(2)

                Spacer()

                if let date = note.date {
                    Text(localizedDateString(date, dateStyle: .medium, timeStyle: .none))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            Text(note.notes)
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.text)
                .lineLimit(3)

            if !note.attachments.isEmpty {
                Text(String(format: localizedAppString("%d attachment(s)"), note.attachments.count))
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

