import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct MedicineHistoryItem: Identifiable {
    let id: String
    let date: Date
    let timeText: String
    let timeSortMinutes: Int
    let name: String

    static func items(from entry: HealthLogEntry) -> [MedicineHistoryItem] {
        let lines = entry.comments
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let parsed = lines.compactMap { line -> MedicineHistoryItem? in
            guard let parsedLine = Self.parseChecklistLine(line) else { return nil }

            return MedicineHistoryItem(
                id: "\(entry.id.uuidString)-\(line)",
                date: entry.timestamp,
                timeText: parsedLine.timeText,
                timeSortMinutes: Self.minutes(from: parsedLine.timeText),
                name: parsedLine.name
            )
        }

        if !parsed.isEmpty {
            return parsed
        }

        return entry.value
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0 != "No medicine checked" }
            .enumerated()
            .map { index, line in
                MedicineHistoryItem(
                    id: "\(entry.id.uuidString)-fallback-\(index)",
                    date: entry.timestamp,
                    timeText: localizedDateString(entry.timestamp, dateStyle: .none, timeStyle: .short),
                    timeSortMinutes: Self.minutes(from: entry.timestamp),
                    name: Self.cleanMedicineName(line)
                )
            }
    }

    private static func parseChecklistLine(_ line: String) -> (timeText: String, name: String)? {
        let separators = [": Checked - ", ": Not checked - "]

        for separator in separators {
            guard let range = line.range(of: separator, options: [.caseInsensitive]) else { continue }

            let timeText = line[..<range.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
            let name = line[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)

            guard !timeText.isEmpty, !name.isEmpty else { return nil }
            return (timeText, cleanMedicineName(name))
        }

        guard let range = line.range(of: ": ", options: [.backwards]) else { return nil }
        let timeText = line[..<range.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
        let name = line[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)

        guard !timeText.isEmpty, !name.isEmpty else { return nil }
        return (timeText, cleanMedicineName(name))
    }

    private static func cleanMedicineName(_ text: String) -> String {
        text
            .replacingOccurrences(of: "Checked - ", with: "", options: [.caseInsensitive])
            .replacingOccurrences(of: "Not checked - ", with: "", options: [.caseInsensitive])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func minutes(from date: Date, calendar: Calendar = .current) -> Int {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    private static func minutes(from text: String) -> Int {
        let normalized = text
            .replacingOccurrences(of: "\u{202F}", with: " ")
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"

        if let parsed = formatter.date(from: normalized.uppercased()) {
            return minutes(from: parsed)
        }

        formatter.dateFormat = "HH:mm"
        if let parsed = formatter.date(from: normalized) {
            return minutes(from: parsed)
        }

        return 0
    }
}

