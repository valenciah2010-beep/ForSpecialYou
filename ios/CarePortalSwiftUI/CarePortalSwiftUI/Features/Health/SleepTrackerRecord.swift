import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct SleepTrackerRecord: Identifiable {
    let id: UUID
    let date: Date
    let startMinutes: Int
    let endMinutes: Int
    let durationText: String
    let durationMinutes: Int
    let qualityTitle: String
    let wakingCount: Int

    var dateLabel: String {
        localizedDateFormatString(date, format: "MMM d")
    }

    init?(entry: HealthLogEntry) {
        guard entry.type == .snapshot, entry.categoryID == "sleep" else { return nil }

        self.id = entry.id
        self.date = entry.timestamp
        self.durationText = Self.durationText(from: entry.value)
        self.qualityTitle = Self.qualityTitle(from: entry.value)
        self.wakingCount = Self.wakingCount(from: entry.value)

        let lines = entry.comments
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        let sleepMinutes = lines
            .first { $0.localizedCaseInsensitiveContains("fell asleep at") }
            .flatMap { Self.minutesFromLine($0, prefix: "Fell asleep at") } ?? (21 * 60)

        let wakeMinutesRaw = lines
            .first { $0.localizedCaseInsensitiveContains("woke up at") }
            .flatMap { Self.minutesFromLine($0, prefix: "Woke up at") } ?? (7 * 60)

        self.startMinutes = Self.timelineMinutes(sleepMinutes)
        let normalizedWakeMinutes = Self.timelineMinutes(wakeMinutesRaw)
        let wakeMinutes = normalizedWakeMinutes <= self.startMinutes
            ? normalizedWakeMinutes + 24 * 60
            : normalizedWakeMinutes
        self.endMinutes = wakeMinutes
        self.durationMinutes = max(0, wakeMinutes - self.startMinutes)
    }

    private static func timelineMinutes(_ minutes: Int) -> Int {
        minutes < 18 * 60 ? minutes + 24 * 60 : minutes
    }

    private static func durationText(from value: String) -> String {
        value
            .components(separatedBy: "·")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? "Sleep"
    }

    private static func qualityTitle(from value: String) -> String {
        let parts = value
            .components(separatedBy: "·")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return parts.dropFirst().first ?? "Sleep"
    }

    private static func wakingCount(from value: String) -> Int {
        value
            .components(separatedBy: "·")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { $0.localizedCaseInsensitiveContains("wake") }
            .flatMap { Int($0.filter(\.isNumber)) } ?? 0
    }

    static func durationText(minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours == 0 {
            return "\(remainingMinutes) min"
        }

        if remainingMinutes == 0 {
            return "\(hours) hr"
        }

        return "\(hours) hr \(remainingMinutes) min"
    }

    private static func minutesFromLine(_ line: String, prefix: String) -> Int? {
        let rawTime = line
            .replacingOccurrences(of: prefix, with: "", options: [.caseInsensitive])
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\u{202F}", with: " ")
            .replacingOccurrences(of: "\u{00A0}", with: " ")

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"

        guard let parsed = formatter.date(from: rawTime) else { return nil }
        let components = Calendar.current.dateComponents([.hour, .minute], from: parsed)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }
}

