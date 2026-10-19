import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct SavedMealEstimate: Codable, Identifiable {
    let id: UUID
    let savedAt: Date
    let imageData: Data
    let estimate: MealNutritionEstimate

    init(id: UUID = UUID(), savedAt: Date, imageData: Data, estimate: MealNutritionEstimate) {
        self.id = id
        self.savedAt = savedAt
        self.imageData = imageData
        self.estimate = estimate
    }
}

