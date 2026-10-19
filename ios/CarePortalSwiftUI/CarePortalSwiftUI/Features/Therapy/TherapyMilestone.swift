import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct TherapyMilestone: Identifiable, Codable {
    let id: UUID
    let categoryID: String
    let categoryTitle: String
    let date: Date
    let milestone: String
    let supportLevel: String
    let notes: String

    init(
        id: UUID = UUID(),
        categoryID: String,
        categoryTitle: String,
        date: Date,
        milestone: String,
        supportLevel: String,
        notes: String
    ) {
        self.id = id
        self.categoryID = categoryID
        self.categoryTitle = categoryTitle
        self.date = date
        self.milestone = milestone
        self.supportLevel = supportLevel
        self.notes = notes
    }
}

