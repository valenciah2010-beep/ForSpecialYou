import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct DiagnosisCategoryTimelineItem: Identifiable {
    enum Kind {
        case doctorVisit
        case note
    }

    let id: String
    let sourceID: UUID
    let date: Date
    let kind: Kind
    let title: String
    let notePreview: String

    var kindTitle: String {
        switch kind {
        case .doctorVisit:
            return localizedAppString("Doctor Visit")
        case .note:
            return localizedAppString("Notes")
        }
    }

    var icon: String {
        switch kind {
        case .doctorVisit:
            return "stethoscope"
        case .note:
            return "note.text"
        }
    }

    var tint: Color {
        switch kind {
        case .doctorVisit:
            return Color(red: 0.19, green: 0.48, blue: 0.82)
        case .note:
            return Color(red: 0.82, green: 0.58, blue: 0.10)
        }
    }
}

