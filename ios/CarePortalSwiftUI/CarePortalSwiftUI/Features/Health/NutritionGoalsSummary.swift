import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct NutritionGoalsSummary: View {
    let goals: NutritionGoals

    private var rows: [String] {
        goals.summaryLines.isEmpty ? [localizedAppString("Nutrition goals saved")] : Array(goals.summaryLines.prefix(4))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(localizedAppString("Nutrition Goals"))
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.text)

            ForEach(rows, id: \.self) { row in
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.accent)

                    Text(localizedSavedAIText(row))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(AppTheme.fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

