import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct MealHistoryView: View {
    let savedMeals: [SavedMealEstimate]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            if savedMeals.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)

                    Text(localizedAppString("No saved meals yet"))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.text)

                    Text(localizedAppString("Saved nutrient estimates will appear here."))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 80)
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(savedMeals) { meal in
                        NavigationLink {
                            MealHistoryDetailView(savedMeal: meal)
                        } label: {
                            MealHistoryThumbnail(savedMeal: meal)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(localizedAppString("Meal History"))
    }
}

