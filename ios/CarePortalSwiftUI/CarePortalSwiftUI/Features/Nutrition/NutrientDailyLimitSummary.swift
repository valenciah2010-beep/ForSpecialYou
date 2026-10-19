import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct NutrientDailyLimitSummary: View {
    let estimateCount: Int
    let limit: Int

    private var estimatesLeft: Int {
        max(0, limit - estimateCount)
    }

    private var limitColor: Color {
        if estimatesLeft == 0 {
            return .red
        }

        if estimatesLeft == limit {
            return AppTheme.accent
        }

        return .orange
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.caption.weight(.bold))

            Text(localizedAppString("Estimates Left Today"))
                .font(.caption.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text("\(estimatesLeft)/\(limit)")
                .font(.caption.weight(.black))
        }
        .foregroundStyle(limitColor)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(limitColor.opacity(0.12))
        .clipShape(Capsule())
    }
}

