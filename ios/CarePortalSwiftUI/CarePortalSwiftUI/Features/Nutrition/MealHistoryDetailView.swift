import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct MealHistoryDetailView: View {
    let savedMeal: SavedMealEstimate
    @State private var activeMealPDF: MealPDFShareItem?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let image = UIImage(data: savedMeal.imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 250)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                Text(localizedDateString(savedMeal.savedAt, dateStyle: .full, timeStyle: .short))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)

                Button {
                    exportSavedMealPDF()
                } label: {
                    Label(localizedAppString("Export as PDF"), systemImage: "doc.richtext.fill")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                MealNutritionEstimateView(estimate: savedMeal.estimate)
            }
            .padding(20)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(localizedAppString("Meal Details"))
        .sheet(item: $activeMealPDF) { item in
            PDFShareSheet(url: item.url)
        }
    }

    private func exportSavedMealPDF() {
        guard let url = MealPDFExporter.export(
            imageData: savedMeal.imageData,
            estimate: savedMeal.estimate,
            savedAt: savedMeal.savedAt
        ) else {
            return
        }

        activeMealPDF = MealPDFShareItem(url: url)
    }
}

