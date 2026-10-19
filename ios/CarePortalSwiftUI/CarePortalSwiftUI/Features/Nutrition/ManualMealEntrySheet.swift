import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct ManualMealEntrySheet: View {
    let onSave: (Data, MealNutritionEstimate) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedMealPhoto: PhotosPickerItem?
    @State private var imageData = Data()
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var fiber = ""
    @State private var sugar = ""
    @State private var summary = ""
    @State private var notes = ""

    private var canSave: Bool {
        !imageData.isEmpty && intValue(calories) > 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    PhotosPicker(selection: $selectedMealPhoto, matching: .images) {
                        ZStack {
                            if let image = UIImage(data: imageData) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                VStack(spacing: 10) {
                                    Image(systemName: "camera.fill")
                                        .font(.title.weight(.bold))
                                        .foregroundStyle(AppTheme.accent)

                                    Text(localizedAppString("Add Meal Photo"))
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(AppTheme.text)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 190)
                        .background(AppTheme.fieldBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)

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
                        Text(localizedAppString("Meal Notes"))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.text)

                        TextField(localizedAppString("Meal summary"), text: $summary, axis: .vertical)
                            .lineLimit(3...5)
                            .nutritionTextFieldStyle()

                        TextField(localizedAppString("Notes"), text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                            .nutritionTextFieldStyle()
                    }
                    .nutritionEditCard()
                }
                .padding(20)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(localizedAppString("Add Meal Manually"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 10) {
                        Button(localizedAppString("Save")) {
                            onSave(imageData, makeEstimate())
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
            .task(id: selectedMealPhoto) {
                await loadSelectedMealPhoto()
            }
        }
    }

    private func loadSelectedMealPhoto() async {
        guard let selectedMealPhoto else { return }

        do {
            if let data = try await selectedMealPhoto.loadTransferable(type: Data.self) {
                await MainActor.run {
                    imageData = data
                }
            }
        } catch {
            // Keep the current draft if photo loading fails.
        }
    }

    private func makeEstimate() -> MealNutritionEstimate {
        let trimmedSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        return MealNutritionEstimate(
            calories: intValue(calories),
            protein: intValue(protein),
            carbs: intValue(carbs),
            fat: intValue(fat),
            fiber: intValue(fiber),
            sugar: intValue(sugar),
            confidence: "manual",
            summary: trimmedSummary.isEmpty ? localizedAppString("Manually entered meal.") : trimmedSummary,
            recommendations: [],
            notes: trimmedNotes.isEmpty ? [] : [trimmedNotes]
        )
    }

    private func intValue(_ text: String) -> Int {
        Int(text.filter(\.isNumber)) ?? 0
    }
}

