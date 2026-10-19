import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct NutritionGoals: Codable, Equatable {
    var calorieGoal = ""
    var proteinGoal = ""
    var carbsGoal = ""
    var fatGoal = ""
    var calciumGoal = ""
    var vitaminDGoal = ""
    var ironGoal = ""
    var otherSupplements = ""
    var waterGoal = ""
    var notes = ""
    var lastUpdated = Date()
    var consumedDateKey = MedicationCheckState.todayKey
    var consumedCalories = 0
    var consumedProtein = 0
    var consumedCarbs = 0
    var consumedFat = 0

    enum CodingKeys: String, CodingKey {
        case calorieGoal
        case proteinGoal
        case carbsGoal
        case fatGoal
        case calciumGoal
        case vitaminDGoal
        case ironGoal
        case otherSupplements
        case waterGoal
        case notes
        case lastUpdated
        case consumedDateKey
        case consumedCalories
        case consumedProtein
        case consumedCarbs
        case consumedFat
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        calorieGoal = try container.decodeIfPresent(String.self, forKey: .calorieGoal) ?? ""
        proteinGoal = try container.decodeIfPresent(String.self, forKey: .proteinGoal) ?? ""
        carbsGoal = try container.decodeIfPresent(String.self, forKey: .carbsGoal) ?? ""
        fatGoal = try container.decodeIfPresent(String.self, forKey: .fatGoal) ?? ""
        calciumGoal = try container.decodeIfPresent(String.self, forKey: .calciumGoal) ?? ""
        vitaminDGoal = try container.decodeIfPresent(String.self, forKey: .vitaminDGoal) ?? ""
        ironGoal = try container.decodeIfPresent(String.self, forKey: .ironGoal) ?? ""
        otherSupplements = try container.decodeIfPresent(String.self, forKey: .otherSupplements) ?? ""
        waterGoal = try container.decodeIfPresent(String.self, forKey: .waterGoal) ?? ""
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        lastUpdated = try container.decodeIfPresent(Date.self, forKey: .lastUpdated) ?? Date()
        consumedDateKey = try container.decodeIfPresent(String.self, forKey: .consumedDateKey) ?? MedicationCheckState.todayKey
        consumedCalories = try container.decodeIfPresent(Int.self, forKey: .consumedCalories) ?? 0
        consumedProtein = try container.decodeIfPresent(Int.self, forKey: .consumedProtein) ?? 0
        consumedCarbs = try container.decodeIfPresent(Int.self, forKey: .consumedCarbs) ?? 0
        consumedFat = try container.decodeIfPresent(Int.self, forKey: .consumedFat) ?? 0
    }

    var isEmpty: Bool {
        [
            calorieGoal,
            proteinGoal,
            carbsGoal,
            fatGoal,
            calciumGoal,
            vitaminDGoal,
            ironGoal,
            otherSupplements,
            waterGoal,
            notes
        ]
        .allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    var summaryLines: [String] {
        var lines: [String] = []
        appendProgressLine("Calories", current: consumedCalories, goal: calorieGoal, unit: "kcal", to: &lines)
        appendProgressLine("Protein", current: consumedProtein, goal: proteinGoal, unit: "g", to: &lines)
        appendProgressLine("Carbs", current: consumedCarbs, goal: carbsGoal, unit: "g", to: &lines)
        appendProgressLine("Fats", current: consumedFat, goal: fatGoal, unit: "g", to: &lines)
        appendLine("Calcium", calciumGoal, "mg", to: &lines)
        appendLine("Vitamin D", vitaminDGoal, "IU", to: &lines)
        appendLine("Iron", ironGoal, "mg", to: &lines)
        appendLine("Water", waterGoal, "", to: &lines)

        let trimmedSupplements = otherSupplements.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSupplements.isEmpty {
            lines.append("Other supplements: \(trimmedSupplements)")
        }

        return lines
    }

    mutating func applyMealEstimate(_ estimate: MealNutritionEstimate) {
        resetDailyProgressIfNeeded()
        consumedCalories += estimate.calories
        consumedProtein += estimate.protein
        consumedCarbs += estimate.carbs
        consumedFat += estimate.fat
        lastUpdated = Date()
    }

    mutating func resetDailyProgressIfNeeded() {
        guard consumedDateKey != MedicationCheckState.todayKey else { return }
        consumedDateKey = MedicationCheckState.todayKey
        consumedCalories = 0
        consumedProtein = 0
        consumedCarbs = 0
        consumedFat = 0
    }

    var hasConsumedNutritionToday: Bool {
        consumedDateKey == MedicationCheckState.todayKey
            && [consumedCalories, consumedProtein, consumedCarbs, consumedFat].contains { $0 > 0 }
    }

    private func appendLine(_ label: String, _ value: String, _ unit: String, to lines: inout [String]) {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else { return }
        lines.append(unit.isEmpty ? "\(label): \(trimmedValue)" : "\(label): \(trimmedValue) \(unit)")
    }

    private func appendProgressLine(_ label: String, current: Int, goal: String, unit: String, to lines: inout [String]) {
        let trimmedGoal = goal.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedGoal.isEmpty {
            lines.append("\(label): \(current)/\(trimmedGoal) \(unit)")
        } else if current > 0 {
            lines.append("\(label): \(current) \(unit)")
        }
    }
}

