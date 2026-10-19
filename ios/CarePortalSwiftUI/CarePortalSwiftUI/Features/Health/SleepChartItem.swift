import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct SleepChartItem: Identifiable {
    let id: String
    let recordID: UUID?
    let date: Date
    let startMinutes: Int
    let endMinutes: Int
    let durationMinutes: Int
    let label: String

    static func items(from records: [SleepTrackerRecord], period: SleepHistoryPeriod, anchorDate: Date) -> [SleepChartItem] {
        if period == .week {
            return weeklyItems(from: records, anchorDate: anchorDate)
        }

        if period == .sixMonths {
            return monthlyItems(from: records)
        }

        return records.enumerated().map { index, record in
            SleepChartItem(
                id: record.id.uuidString,
                recordID: record.id,
                date: record.date,
                startMinutes: record.startMinutes,
                endMinutes: record.endMinutes,
                durationMinutes: record.durationMinutes,
                label: label(for: record, index: index, total: records.count, period: period)
            )
        }
    }

    private static func weeklyItems(from records: [SleepTrackerRecord], anchorDate: Date) -> [SleepChartItem] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: anchorDate)

        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset - 6, to: today) else {
                return nil
            }

            if let record = records
                .filter({ calendar.isDate($0.date, inSameDayAs: date) })
                .sorted(by: { $0.date > $1.date })
                .first {
                return SleepChartItem(
                    id: record.id.uuidString,
                    recordID: record.id,
                    date: record.date,
                    startMinutes: record.startMinutes,
                    endMinutes: record.endMinutes,
                    durationMinutes: record.durationMinutes,
                    label: localizedDateFormatString(date, format: "EEE")
                )
            }

            return SleepChartItem(
                id: "empty-\(date.timeIntervalSince1970)",
                recordID: nil,
                date: date,
                startMinutes: 22 * 60,
                endMinutes: 22 * 60,
                durationMinutes: 0,
                label: localizedDateFormatString(date, format: "EEE")
            )
        }
    }

    private static func label(for record: SleepTrackerRecord, index: Int, total: Int, period: SleepHistoryPeriod) -> String {
        switch period {
        case .day, .week:
            return localizedDateFormatString(record.date, format: "EEE")
        case .month:
            guard total <= 10 || index == total / 2 else { return "" }
            return localizedDateFormatString(record.date, format: "MMM")
        case .sixMonths:
            return localizedDateFormatString(record.date, format: "MMM")
        }
    }

    private static func monthlyItems(from records: [SleepTrackerRecord]) -> [SleepChartItem] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: records) { record in
            let components = calendar.dateComponents([.year, .month], from: record.date)
            return "\(components.year ?? 0)-\(components.month ?? 0)"
        }

        return groups.compactMap { key, values in
            guard let first = values.sorted(by: { $0.date < $1.date }).first else { return nil }
            let count = max(1, values.count)
            let start = values.reduce(0) { $0 + $1.startMinutes } / count
            let end = values.reduce(0) { $0 + $1.endMinutes } / count
            let duration = values.reduce(0) { $0 + $1.durationMinutes } / count

            return SleepChartItem(
                id: key,
                recordID: nil,
                date: first.date,
                startMinutes: start,
                endMinutes: max(end, start + 8),
                durationMinutes: duration,
                label: localizedDateFormatString(first.date, format: "MMM")
            )
        }
        .sorted { $0.date < $1.date }
    }
}

