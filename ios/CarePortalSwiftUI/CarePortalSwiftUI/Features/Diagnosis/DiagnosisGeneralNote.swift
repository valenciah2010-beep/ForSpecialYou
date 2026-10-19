import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct DiagnosisGeneralNote: Codable, Identifiable, Equatable {
    let id: UUID
    let categoryIDs: [String]
    let date: Date?
    let notes: String
    let attachments: [DiagnosisAttachment]
    let createdAt: Date

    init(
        id: UUID = UUID(),
        categoryIDs: [String],
        date: Date?,
        notes: String,
        attachments: [DiagnosisAttachment],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.categoryIDs = categoryIDs
        self.date = date
        self.notes = notes
        self.attachments = attachments
        self.createdAt = createdAt
    }

    var categoryText: String {
        diagnosisCategoryText(categoryIDs)
    }
}

