import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct NutritionGoalsEditor: View {
    @Binding var goals: NutritionGoals

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            NutritionGoalSection(title: "Calories") {
                NutritionGoalField(title: "Daily calorie goal", placeholder: "kcal", text: $goals.calorieGoal)
            }

            NutritionGoalSection(title: "Macronutrients") {
                NutritionGoalField(title: "Protein", placeholder: "grams", text: $goals.proteinGoal)
                NutritionGoalField(title: "Carbs", placeholder: "grams", text: $goals.carbsGoal)
                NutritionGoalField(title: "Fats", placeholder: "grams", text: $goals.fatGoal)
            }

            NutritionGoalSection(title: "Micronutrient Supplementation") {
                NutritionGoalField(title: "Calcium", placeholder: "mg", text: $goals.calciumGoal)
                NutritionGoalField(title: "Vitamin D", placeholder: "IU", text: $goals.vitaminDGoal)
                NutritionGoalField(title: "Iron", placeholder: "mg", text: $goals.ironGoal)

                TextField("Other supplements or vitamins", text: $goals.otherSupplements, axis: .vertical)
                    .textInputAutocapitalization(.never)
                    .lineLimit(2...4)
                    .padding(12)
                    .background(AppTheme.fieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            NutritionGoalSection(title: "Water Hydration") {
                NutritionGoalField(title: "Daily water goal", placeholder: "cups or oz", text: $goals.waterGoal)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(localizedAppString("Notes"))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.text)

                TextField(localizedAppString("Diet restrictions, feeding notes, texture needs, or parent reminders"), text: $goals.notes, axis: .vertical)
                    .textInputAutocapitalization(.never)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(AppTheme.fieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }
}

