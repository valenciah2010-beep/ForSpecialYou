import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

enum MedicationDayTime: String, CaseIterable, Codable, Identifiable {
    case morning
    case noon
    case evening
    case dose4
    case dose5
    case dose6
    case dose7
    case dose8
    case dose9
    case dose10

    var id: String { rawValue }

    var title: String {
        switch self {
        case .morning:
            return "Dose 1"
        case .noon:
            return "Dose 2"
        case .evening:
            return "Dose 3"
        case .dose4:
            return "Dose 4"
        case .dose5:
            return "Dose 5"
        case .dose6:
            return "Dose 6"
        case .dose7:
            return "Dose 7"
        case .dose8:
            return "Dose 8"
        case .dose9:
            return "Dose 9"
        case .dose10:
            return "Dose 10"
        }
    }

    var defaultClockTime: String {
        switch self {
        case .morning:
            return "08:00"
        case .noon:
            return "12:00"
        case .evening:
            return "18:00"
        case .dose4:
            return "20:00"
        case .dose5:
            return "22:00"
        case .dose6:
            return "23:00"
        case .dose7:
            return "06:00"
        case .dose8:
            return "10:00"
        case .dose9:
            return "14:00"
        case .dose10:
            return "16:00"
        }
    }
}

