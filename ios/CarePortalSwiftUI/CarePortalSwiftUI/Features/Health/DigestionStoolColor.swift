import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

enum DigestionStoolColor: String, CaseIterable, Identifiable {
    case brown
    case green
    case clayWhite
    case black
    case red

    var id: String { rawValue }

    var title: String {
        switch self {
        case .brown:
            return "Brown"
        case .green:
            return "Green"
        case .clayWhite:
            return "Clay/White"
        case .black:
            return "Black"
        case .red:
            return "Red"
        }
    }

    var swatch: Color {
        switch self {
        case .brown:
            return Color(red: 0.48, green: 0.25, blue: 0.13)
        case .green:
            return Color(red: 0.28, green: 0.55, blue: 0.25)
        case .clayWhite:
            return Color(red: 0.90, green: 0.86, blue: 0.72)
        case .black:
            return Color(red: 0.08, green: 0.07, blue: 0.06)
        case .red:
            return Color(red: 0.73, green: 0.12, blue: 0.11)
        }
    }
}

