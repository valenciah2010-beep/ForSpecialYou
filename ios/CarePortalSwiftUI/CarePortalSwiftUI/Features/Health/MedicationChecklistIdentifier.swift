import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

enum MedicationChecklistIdentifier {
    static func id(for medication: MedicationSchedule, day: MedicationWeekday?, time: MedicationDayTime) -> String {
        switch medication.mode {
        case .daily:
            return "\(medication.id.uuidString).\(time.rawValue)"
        case .intervalDays:
            return "\(medication.id.uuidString).interval.\(time.rawValue)"
        case .weekly:
            let dayKey = day?.rawValue ?? MedicationWeekday.today().rawValue
            return "\(medication.id.uuidString).\(dayKey).\(time.rawValue)"
        }
    }
}

