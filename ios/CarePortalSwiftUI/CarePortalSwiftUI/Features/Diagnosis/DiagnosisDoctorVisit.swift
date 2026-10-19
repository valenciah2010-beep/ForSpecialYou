import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct DiagnosisDoctorVisit: Codable, Identifiable, Equatable {
    let id: UUID
    let categoryIDs: [String]
    let title: String
    let doctorName: String
    let clinicLocation: String
    let date: Date
    let notes: String
    let attachments: [DiagnosisAttachment]
    let createdAt: Date

    init(
        id: UUID = UUID(),
        categoryIDs: [String],
        title: String = "",
        doctorName: String,
        clinicLocation: String,
        date: Date,
        notes: String,
        attachments: [DiagnosisAttachment],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.categoryIDs = categoryIDs
        self.title = title
        self.doctorName = doctorName
        self.clinicLocation = clinicLocation
        self.date = date
        self.notes = notes
        self.attachments = attachments
        self.createdAt = createdAt
    }

    var categoryText: String {
        diagnosisCategoryText(categoryIDs)
    }

    var displayTitle: String {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTitle.isEmpty {
            return trimmedTitle
        }

        let trimmedDoctorName = doctorName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedDoctorName.isEmpty ? localizedAppString("Doctor Visit") : trimmedDoctorName
    }

    enum CodingKeys: String, CodingKey {
        case id
        case categoryIDs
        case title
        case doctorName
        case clinicLocation
        case date
        case notes
        case attachments
        case createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.categoryIDs = try container.decode([String].self, forKey: .categoryIDs)
        self.title = (try? container.decode(String.self, forKey: .title)) ?? ""
        self.doctorName = try container.decode(String.self, forKey: .doctorName)
        self.clinicLocation = try container.decode(String.self, forKey: .clinicLocation)
        self.date = try container.decode(Date.self, forKey: .date)
        self.notes = try container.decode(String.self, forKey: .notes)
        self.attachments = try container.decode([DiagnosisAttachment].self, forKey: .attachments)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
}

