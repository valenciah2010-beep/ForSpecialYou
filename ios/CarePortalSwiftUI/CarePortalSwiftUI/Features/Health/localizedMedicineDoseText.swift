import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

func localizedMedicineDoseText(_ text: String) -> String {
    var localizedText = text
    let terms = [
        "Tablet(s)",
        "Capsule(s)",
        "Drop(s)",
        "Dose",
        "Round Tablet",
        "Capsule",
        "Liquid",
        "Injection",
        "Drops",
        "Other"
    ]

    for term in terms {
        localizedText = localizedText.replacingOccurrences(of: term, with: localizedAppString(term))
    }

    return localizedText
}

