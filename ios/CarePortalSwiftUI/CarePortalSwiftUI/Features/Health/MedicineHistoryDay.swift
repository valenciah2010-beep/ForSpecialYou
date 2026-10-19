import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct MedicineHistoryDay: Identifiable {
    let id: String
    let date: Date
    let items: [MedicineHistoryItem]

    var dateTitle: String {
        localizedDateString(date, dateStyle: .full, timeStyle: .none)
    }

    var savedTimeText: String {
        localizedDateString(date, dateStyle: .none, timeStyle: .short)
    }

    static func days(from entries: [HealthLogEntry], calendar: Calendar = .current) -> [MedicineHistoryDay] {
        let sortedEntries = entries.sorted { $0.timestamp > $1.timestamp }
        var seenDateKeys = Set<String>()
        var days: [MedicineHistoryDay] = []

        for entry in sortedEntries {
            let key = MedicationCheckState.dateKey(for: entry.timestamp, calendar: calendar)
            guard !seenDateKeys.contains(key) else { continue }

            let sortedItems = MedicineHistoryItem.items(from: entry).sorted { first, second in
                if first.timeSortMinutes == second.timeSortMinutes {
                    return first.name.localizedCaseInsensitiveCompare(second.name) == .orderedAscending
                }

                return first.timeSortMinutes < second.timeSortMinutes
            }

            guard !sortedItems.isEmpty else { continue }
            seenDateKeys.insert(key)

            days.append(
                MedicineHistoryDay(
                    id: key,
                    date: entry.timestamp,
                    items: sortedItems
                )
            )
        }

        return days
    }
}

