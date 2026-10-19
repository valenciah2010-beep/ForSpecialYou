import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

enum BristolStoolGuide {
    static func group(for type: Int) -> String {
        switch type {
        case 1...2:
            return "Constipation"
        case 3...4:
            return "Optimal"
        default:
            return "Diarrhea/Intolerance"
        }
    }

    static func description(for type: Int) -> String {
        switch type {
        case 1:
            return "Separate hard lumps, like little pebbles."
        case 2:
            return "Hard and lumpy, starting to resemble a sausage."
        case 3:
            return "Sausage-shaped with cracks on the surface."
        case 4:
            return "Smooth and soft, snake-like."
        case 5:
            return "Soft blobs with clear-cut edges."
        case 6:
            return "Fluffy, mushy pieces with ragged edges."
        default:
            return "Watery with no solid pieces."
        }
    }

    static func severity(for type: Int) -> Int {
        switch type {
        case 3...4:
            return 1
        case 2, 5:
            return 2
        default:
            return 3
        }
    }
}

