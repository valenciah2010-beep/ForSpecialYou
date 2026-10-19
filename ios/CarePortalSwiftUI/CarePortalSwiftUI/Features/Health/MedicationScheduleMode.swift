import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

enum MedicationScheduleMode: String, CaseIterable, Codable, Identifiable {
    case daily
    case intervalDays
    case weekly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily:
            return "Daily"
        case .intervalDays:
            return "Every X days"
        case .weekly:
            return "Certain days of the week"
        }
    }
}

