import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct NutritionGoalsPage: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var goals: NutritionGoals
    let onSave: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    PageHeader(
                        icon: "leaf.fill",
                        title: "Nutrition Goals",
                        subtitle: "Calories, macros, supplements, and hydration"
                    )

                    NutritionGoalsSummary(goals: goals)

                    NutritionGoalsEditor(goals: $goals)
                        .padding(16)
                        .background(AppTheme.panel)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(20)
            }

            StickyBottomSaveButton(title: "Save", tint: AppTheme.accent) {
                onSave()
                dismiss()
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(localizedAppString("Nutrition Goals"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

