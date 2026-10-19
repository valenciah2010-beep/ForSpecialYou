import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

enum SkinSeverityLevel: String, CaseIterable, Identifiable {
    case mild = "Mild"
    case moderate = "Moderate"
    case severe = "Severe"

    var id: String { rawValue }

    var score: Int {
        switch self {
        case .mild:
            return 1
        case .moderate:
            return 3
        case .severe:
            return 5
        }
    }

    var description: String {
        switch self {
        case .mild:
            return "Localized redness, slight itch, isolated spots"
        case .moderate:
            return "Spreading hives, widespread rash, significant scratching"
        case .severe:
            return "Rapidly spreading, swelling of face/lips"
        }
    }

    var color: Color {
        switch self {
        case .mild:
            return Color(red: 0.43, green: 0.77, blue: 0.52)
        case .moderate:
            return Color(red: 0.95, green: 0.69, blue: 0.22)
        case .severe:
            return Color(red: 0.90, green: 0.25, blue: 0.25)
        }
    }
}

