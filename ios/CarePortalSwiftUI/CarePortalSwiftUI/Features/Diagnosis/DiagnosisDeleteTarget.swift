import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct DiagnosisDeleteTarget: Identifiable {
    enum Kind {
        case condition(DiagnosisCondition)
        case category(DiagnosisOption)
    }

    let id = UUID()
    let kind: Kind

    var titleKey: String {
        switch kind {
        case .condition:
            return "Delete condition?"
        case .category:
            return "Remove category from page?"
        }
    }

    var messageKey: String {
        switch kind {
        case .condition:
            return "This condition will be removed."
        case .category:
            return "This category will be hidden from the page but still available in Edit."
        }
    }
}

