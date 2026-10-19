import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct MealNutritionEstimateView: View {
    let estimate: MealNutritionEstimate

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(localizedAppString("AI Estimate"))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.text)

                    Text(LocalizedStringKey(estimate.confidence))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "sparkles")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.accent)
            }

            HStack(spacing: 12) {
                MetricCard(title: "Calories", value: "\(estimate.calories)", unit: "kcal", icon: "flame.fill")
                MetricCard(title: "Protein", value: "\(estimate.protein)", unit: "g", icon: "bolt.heart.fill")
            }

            MealReportTextSection(
                title: "Summary",
                icon: "text.alignleft",
                text: estimate.summary
            )

            MealReportListSection(
                title: "Recommendations",
                icon: "lightbulb.fill",
                items: estimate.recommendations
            )

            VStack(alignment: .leading, spacing: 12) {
                HealthMetricRow(icon: "leaf.fill", title: "Carbs", value: "\(estimate.carbs) g")
                HealthMetricRow(icon: "drop.fill", title: "Fat", value: "\(estimate.fat) g")
                HealthMetricRow(icon: "circle.hexagongrid.fill", title: "Fiber", value: "\(estimate.fiber) g")
                HealthMetricRow(icon: "cube.fill", title: "Sugar", value: "\(estimate.sugar) g")
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(estimate.notes, id: \.self) { note in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppTheme.accent)

                        Text(localizedSavedAIText(note))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

