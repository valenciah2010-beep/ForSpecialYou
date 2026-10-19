import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct MealNutritionEstimate: Codable {
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let fiber: Int
    let sugar: Int
    let confidence: String
    let summary: String
    let recommendations: [String]
    let notes: [String]

    enum CodingKeys: String, CodingKey {
        case calories
        case protein
        case carbs
        case fat
        case fiber
        case sugar
        case confidence
        case summary
        case recommendations
        case notes
    }

    init(
        calories: Int,
        protein: Int,
        carbs: Int,
        fat: Int,
        fiber: Int,
        sugar: Int,
        confidence: String,
        summary: String,
        recommendations: [String],
        notes: [String]
    ) {
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.confidence = confidence
        self.summary = summary
        self.recommendations = recommendations
        self.notes = notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        calories = try container.decode(Int.self, forKey: .calories)
        protein = try container.decode(Int.self, forKey: .protein)
        carbs = try container.decode(Int.self, forKey: .carbs)
        fat = try container.decode(Int.self, forKey: .fat)
        fiber = try container.decode(Int.self, forKey: .fiber)
        sugar = try container.decode(Int.self, forKey: .sugar)
        confidence = try container.decode(String.self, forKey: .confidence)
        summary = try container.decodeIfPresent(String.self, forKey: .summary) ?? localizedAppString("This is a photo-based meal estimate.")
        recommendations = try container.decodeIfPresent([String].self, forKey: .recommendations) ?? []
        notes = try container.decodeIfPresent([String].self, forKey: .notes) ?? []
    }
}

