import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct MedicationCheckState: Codable, Equatable {
    var dateKey: String
    var checkedIDs: [String]

    static var todayKey: String {
        dateKey(for: Date())
    }

    static func today() -> MedicationCheckState {
        MedicationCheckState(dateKey: todayKey, checkedIDs: [])
    }

    static func dateKey(for date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }
}

