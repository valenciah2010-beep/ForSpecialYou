import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct MealEstimateEditorSheet: View {
    let title: String
    let estimate: MealNutritionEstimate
    var requiresPhoto = false
    var imageData: Data = Data()
    let onSave: (MealNutritionEstimate) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var calories: String
    @State private var protein: String
    @State private var carbs: String
    @State private var fat: String
    @State private var fiber: String
    @State private var sugar: String
    @State private var summary: String
    @State private var recommendations: String
    @State private var notes: String

    init(
        title: String,
        estimate: MealNutritionEstimate,
        requiresPhoto: Bool = false,
        imageData: Data = Data(),
        onSave: @escaping (MealNutritionEstimate) -> Void
    ) {
        self.title = title
        self.estimate = estimate
        self.requiresPhoto = requiresPhoto
        self.imageData = imageData
        self.onSave = onSave
        self._calories = State(initialValue: "\(estimate.calories)")
        self._protein = State(initialValue: "\(estimate.protein)")
        self._carbs = State(initialValue: "\(estimate.carbs)")
        self._fat = State(initialValue: "\(estimate.fat)")
        self._fiber = State(initialValue: "\(estimate.fiber)")
        self._sugar = State(initialValue: "\(estimate.sugar)")
        self._summary = State(initialValue: estimate.summary)
        self._recommendations = State(initialValue: estimate.recommendations.joined(separator: "\n"))
        self._notes = State(initialValue: estimate.notes.joined(separator: "\n"))
    }

    private var canSave: Bool {
        (!requiresPhoto || !imageData.isEmpty)
            && intValue(calories) > 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let image = UIImage(data: imageData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text(localizedAppString("Calories"))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.text)

                        NutrientNumberInput(title: "Calories", unit: "kcal", text: $calories)
                    }
                    .nutritionEditCard()

                    VStack(alignment: .leading, spacing: 12) {
                        Text(localizedAppString("Macronutrients"))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.text)

                        NutrientNumberInput(title: "Protein", unit: "g", text: $protein)
                        NutrientNumberInput(title: "Carbs", unit: "g", text: $carbs)
                        NutrientNumberInput(title: "Fat", unit: "g", text: $fat)
                    }
                    .nutritionEditCard()

                    VStack(alignment: .leading, spacing: 12) {
                        Text(localizedAppString("More Nutrition Details"))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.text)

                        NutrientNumberInput(title: "Fiber", unit: "g", text: $fiber)
                        NutrientNumberInput(title: "Sugar", unit: "g", text: $sugar)
                    }
                    .nutritionEditCard()

                    VStack(alignment: .leading, spacing: 12) {
                        Text(localizedAppString("Summary"))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.text)

                        TextField(localizedAppString("Meal summary"), text: $summary, axis: .vertical)
                            .lineLimit(3...5)
                            .nutritionTextFieldStyle()

                        Text(localizedAppString("Recommendations"))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(AppTheme.text)

                        TextField(localizedAppString("One recommendation per line"), text: $recommendations, axis: .vertical)
                            .lineLimit(3...6)
                            .nutritionTextFieldStyle()

                        Text(localizedAppString("Notes"))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(AppTheme.text)

                        TextField(localizedAppString("One note per line"), text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                            .nutritionTextFieldStyle()
                    }
                    .nutritionEditCard()
                }
                .padding(20)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(localizedAppString(title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 10) {
                        Button(localizedAppString("Save")) {
                            onSave(makeEstimate())
                            dismiss()
                        }
                        .fontWeight(.bold)
                        .foregroundStyle(canSave ? AppTheme.accent : .secondary)
                        .disabled(!canSave)

                        ToolbarCloseButton {
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    private func makeEstimate() -> MealNutritionEstimate {
        MealNutritionEstimate(
            calories: intValue(calories),
            protein: intValue(protein),
            carbs: intValue(carbs),
            fat: intValue(fat),
            fiber: intValue(fiber),
            sugar: intValue(sugar),
            confidence: estimate.confidence,
            summary: summary.trimmingCharacters(in: .whitespacesAndNewlines),
            recommendations: lineList(from: recommendations),
            notes: lineList(from: notes)
        )
    }

    private func intValue(_ text: String) -> Int {
        Int(text.filter(\.isNumber)) ?? 0
    }

    private func lineList(from text: String) -> [String] {
        text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

