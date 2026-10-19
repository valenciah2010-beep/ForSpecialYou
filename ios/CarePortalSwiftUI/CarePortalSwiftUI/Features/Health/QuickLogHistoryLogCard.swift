import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct QuickLogHistoryLogCard: View {
    let entry: HealthLogEntry
    let option: QuickLogOption

    private var cleanedComments: [String] {
        entry.comments
            .components(separatedBy: .newlines)
            .flatMap { $0.components(separatedBy: "\n\n") }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private var scaleMax: Int {
        option.id == "mood" ? 7 : 5
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: option.icon)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(option.tint)
                    .frame(width: 42, height: 42)
                    .background(option.tint.opacity(0.15))
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

                Text("\(entry.severity)/\(scaleMax)")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(option.tint)
                    .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 8) {
                if !entry.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    SeizureHistoryDetailRow(title: primaryValueTitle, value: entry.value)
                }

                ForEach(cleanedComments, id: \.self) { comment in
                    let parts = splitComment(comment)
                    SeizureHistoryDetailRow(title: parts.title, value: parts.value)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
    }

    private func splitComment(_ comment: String) -> (title: String, value: String) {
        guard let colonIndex = comment.firstIndex(of: ":") else {
            return ("Notes", comment)
        }

        let title = String(comment[..<colonIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
        let value = String(comment[comment.index(after: colonIndex)...]).trimmingCharacters(in: .whitespacesAndNewlines)
        return (title.isEmpty ? "Notes" : title, value.isEmpty ? comment : value)
    }

    private var primaryValueTitle: String {
        switch option.id {
        case "pain":
            return "Pain Location"
        case "cyclicVomiting":
            return "Episodes"
        case "meltdown":
            return "Summary"
        case "stimming":
            return "Summary"
        default:
            return "Mood"
        }
    }
}

