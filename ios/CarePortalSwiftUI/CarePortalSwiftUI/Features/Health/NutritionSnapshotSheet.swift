import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct NutritionSnapshotSheet: View {
    @Environment(\.dismiss) private var dismiss

    let userID: Int
    let option: SnapshotOption
    let onSave: (HealthLogEntry) -> Void

    @AppStorage private var goalsData: Data
    @State private var goals = NutritionGoals()
    @State private var isGoalsExpanded = false

    init(userID: Int, option: SnapshotOption, onSave: @escaping (HealthLogEntry) -> Void) {
        self.userID = userID
        self.option = option
        self.onSave = onSave
        self._goalsData = AppStorage(wrappedValue: Data(), "nutrient.\(userID).nutritionGoalsData")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 16) {
                            if goals.isEmpty {
                                NutritionGoalsEditor(goals: $goals)
                            } else {
                                NutritionGoalsSummary(goals: goals)

                                DisclosureGroup(isExpanded: $isGoalsExpanded) {
                                    NutritionGoalsEditor(goals: $goals)
                                        .padding(.top, 12)
                                } label: {
                                    Text(localizedAppString("View Nutrition Goals"))
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(AppTheme.accent)
                                }
                                .tint(AppTheme.accent)
                            }
                        }
                        .authPanel()
                    }
                    .padding(18)
                }
                StickyBottomSaveButton(title: "Save", tint: AppTheme.accent) {
                    save()
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ToolbarCloseButton {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .principal) {
                    ModalToolbarTitle(icon: option.icon, title: option.title, tint: option.tint)
                }

            }
        }
        .presentationDetents([.large])
        .onAppear {
            goals = storedGoals
            let previousDateKey = goals.consumedDateKey
            goals.resetDailyProgressIfNeeded()
            if previousDateKey != goals.consumedDateKey {
                saveGoals(goals)
            }
            isGoalsExpanded = goals.isEmpty
        }
    }

    private func save() {
        goals.lastUpdated = Date()
        saveGoals(goals)

        let summaryLines = goals.summaryLines
        let entry = HealthLogEntry(
            id: UUID(),
            type: .snapshot,
            categoryID: option.id,
            title: option.title,
            timestamp: Date(),
            severity: 1,
            value: summaryLines.isEmpty ? "Nutrition goals saved" : summaryLines.joined(separator: "\n"),
            comments: goals.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        onSave(entry)
        dismiss()
    }

    private var storedGoals: NutritionGoals {
        guard !goalsData.isEmpty,
              let savedGoals = try? JSONDecoder().decode(NutritionGoals.self, from: goalsData) else {
            return NutritionGoals()
        }

        return savedGoals
    }

    private func saveGoals(_ goals: NutritionGoals) {
        if let data = try? JSONEncoder().encode(goals) {
            goalsData = data
        }
    }
}

