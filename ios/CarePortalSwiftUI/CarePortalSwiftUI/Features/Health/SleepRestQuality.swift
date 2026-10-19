import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

enum SleepRestQuality: String, CaseIterable, Identifiable {
    case restless
    case normal
    case deep

    var id: String { rawValue }

    init?(title: String) {
        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let match = Self.allCases.first(where: {
            $0.title.localizedCaseInsensitiveCompare(normalizedTitle) == .orderedSame
        }) else {
            return nil
        }

        self = match
    }

    var title: String {
        switch self {
        case .restless:
            return "Restless"
        case .normal:
            return "Normal"
        case .deep:
            return "Deep"
        }
    }

    var emoji: String {
        switch self {
        case .restless:
            return "😣"
        case .normal:
            return "😴"
        case .deep:
            return "🌙"
        }
    }

    var severity: Int {
        switch self {
        case .restless:
            return 4
        case .normal:
            return 2
        case .deep:
            return 1
        }
    }
}

