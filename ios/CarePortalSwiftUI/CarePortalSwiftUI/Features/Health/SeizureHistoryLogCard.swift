import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct SeizureHistoryLogCard: View {
    let entry: HealthLogEntry
    let tint: Color

    private var valueParts: [String] {
        entry.value
            .components(separatedBy: "·")
            .map { clean($0) }
    }

    private var duration: String? {
        guard let candidate = valueParts.first, durationSeconds(candidate) > 0 else { return nil }
        return candidate
    }

    private var seizureType: String? {
        guard valueParts.count > 1 else { return nil }
        let candidate = valueParts[1]
        guard !candidate.isEmpty, candidate != "Seizure Type" else { return nil }
        return candidate
    }

    private var triggers: String? {
        commentValue(prefix: "Triggers:")
    }

    private var memoNotes: String? {
        commentValue(prefix: "Post-event notes:") ?? commentValue(prefix: "Memo notes:")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "timer")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(tint)
                    .frame(width: 42, height: 42)
                    .background(tint.opacity(0.15))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.timestamp, format: .dateTime.month().day().year())
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.text)

                    Text(entry.timestamp, format: .dateTime.hour().minute())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(entry.severity)/5")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(tint)
                    .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 8) {
                if let duration {
                    SeizureHistoryDetailRow(title: "Duration", value: duration)
                }

                if let seizureType {
                    SeizureHistoryDetailRow(title: "Seizure Type", value: seizureType)
                }

                if let triggers {
                    SeizureHistoryDetailRow(title: "Triggers", value: triggers)
                }

                if let memoNotes {
                    SeizureHistoryDetailRow(title: "Memo Notes", value: memoNotes)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
    }

    private func commentValue(prefix: String) -> String? {
        let matches = entry.comments
            .components(separatedBy: "\n\n")
            .map { clean($0) }
            .first { $0.range(of: prefix, options: [.anchored, .caseInsensitive]) != nil }

        guard let matches else { return nil }
        let value = clean(String(matches.dropFirst(prefix.count)))
        return value.isEmpty ? nil : value
    }

    private func durationSeconds(_ text: String) -> Int {
        let pieces = text.split(separator: ":").compactMap { Int($0) }

        if pieces.count == 2 {
            return pieces[0] * 60 + pieces[1]
        }

        if pieces.count == 3 {
            return pieces[0] * 3600 + pieces[1] * 60 + pieces[2]
        }

        return 0
    }

    private func clean(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

