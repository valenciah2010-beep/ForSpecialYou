import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct MealHistoryThumbnail: View {
    let savedMeal: SavedMealEstimate

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let image = UIImage(data: savedMeal.imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 150)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppTheme.fieldBackground)
                    .frame(height: 150)
                    .overlay {
                        Image(systemName: "fork.knife")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(AppTheme.accent)
                    }
            }

            Text(localizedDateString(savedMeal.savedAt, dateStyle: .medium, timeStyle: .short))
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)

            Text("\(savedMeal.estimate.calories) kcal")
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.text)
        }
        .padding(10)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 6)
    }
}

