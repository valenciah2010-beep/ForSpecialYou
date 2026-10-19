import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

enum SleepHistoryPeriod: String, CaseIterable, Identifiable {
    case day
    case week
    case month
    case sixMonths

    var id: String { rawValue }

    var shortTitle: String {
        switch self {
        case .day:
            return "D"
        case .week:
            return "W"
        case .month:
            return "M"
        case .sixMonths:
            return "6M"
        }
    }

    func contains(_ date: Date, relativeTo anchorDate: Date) -> Bool {
        let calendar = Calendar.current
        let anchorEndOfDay = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: calendar.startOfDay(for: anchorDate)) ?? anchorDate
        switch self {
        case .day:
            return calendar.isDate(date, inSameDayAs: anchorDate)
        case .week:
            guard let startDate = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: anchorDate)) else {
                return false
            }
            return date >= startDate && date <= anchorEndOfDay
        case .month:
            guard let startDate = calendar.date(byAdding: .day, value: -29, to: calendar.startOfDay(for: anchorDate)) else {
                return false
            }
            return date >= startDate && date <= anchorEndOfDay
        case .sixMonths:
            guard let startDate = calendar.date(byAdding: .month, value: -5, to: calendar.startOfDay(for: anchorDate)) else {
                return false
            }
            return date >= startDate && date <= anchorEndOfDay
        }
    }

    func rangeText(relativeTo anchorDate: Date) -> String {
        let calendar = Calendar.current
        let startDate: Date
        switch self {
        case .day:
            startDate = anchorDate
        case .week:
            startDate = calendar.date(byAdding: .day, value: -6, to: anchorDate) ?? anchorDate
        case .month:
            startDate = calendar.date(byAdding: .day, value: -29, to: anchorDate) ?? anchorDate
        case .sixMonths:
            startDate = calendar.date(byAdding: .month, value: -5, to: anchorDate) ?? anchorDate
        }

        if calendar.isDate(startDate, inSameDayAs: anchorDate) {
            return localizedDateString(anchorDate, dateStyle: .medium, timeStyle: .none)
        }

        return "\(localizedDateFormatString(startDate, format: "MMM d"))–\(localizedDateString(anchorDate, dateStyle: .medium, timeStyle: .none))"
    }
}

