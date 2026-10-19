import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

func diagnosisCategoryText(_ categoryIDs: [String]) -> String {
    let names = categoryIDs.compactMap { id in
        DiagnosisOption.option(id: id).map { localizedAppString($0.title) }
    }

    return names.isEmpty ? localizedAppString("No category selected") : names.joined(separator: ", ")
}

