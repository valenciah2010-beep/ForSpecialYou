import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct DiagnosisConditionCard: View {
    let condition: DiagnosisCondition

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(condition.categoryText)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .lineLimit(2)

            Text(condition.name)
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.text)
                .lineLimit(3)

            if !condition.photos.isEmpty {
                Text(String(format: localizedAppString("%d photo(s)"), condition.photos.count))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

