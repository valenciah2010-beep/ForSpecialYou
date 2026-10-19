import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct DiagnosisCondition: Codable, Identifiable, Equatable {
    let id: UUID
    let categoryIDs: [String]
    let name: String
    let notes: String
    let photos: [DiagnosisAttachment]
    let createdAt: Date

    init(
        id: UUID = UUID(),
        categoryIDs: [String],
        name: String,
        notes: String,
        photos: [DiagnosisAttachment],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.categoryIDs = categoryIDs
        self.name = name
        self.notes = notes
        self.photos = photos
        self.createdAt = createdAt
    }

    var categoryText: String {
        let names = categoryIDs.compactMap { id in
            DiagnosisOption.option(id: id).map { localizedAppString($0.title) }
        }

        return names.isEmpty ? localizedAppString("No category selected") : names.joined(separator: ", ")
    }
}

