import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

enum MedicationTimeFormatting {
    static func displayText(for storedTime: String) -> String {
        let minutes = minutes(for: storedTime)
        let hour = minutes / 60
        let minute = minutes % 60
        let languageCode = UserDefaults.standard.string(forKey: AppLanguage.storageKey) ?? AppLanguage.english.rawValue
        if AppLanguage(code: languageCode) == .chinese {
            return String(format: "%02d:%02d", hour, minute)
        }

        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour % 12 == 0 ? 12 : hour % 12
        return String(format: "%d:%02d %@", displayHour, minute, period)
    }

    static func minutes(for storedTime: String) -> Int {
        let pieces = storedTime.split(separator: ":").compactMap { Int($0) }
        guard pieces.count == 2 else { return 0 }
        return max(0, min(23, pieces[0])) * 60 + max(0, min(59, pieces[1]))
    }

    static func storedTime(from date: Date, calendar: Calendar = .current) -> String {
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        return String(format: "%02d:%02d", hour, minute)
    }

    static func date(from storedTime: String, calendar: Calendar = .current) -> Date {
        let minutes = minutes(for: storedTime)
        let hour = minutes / 60
        let minute = minutes % 60
        return calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: Date()
        ) ?? Date()
    }
}

