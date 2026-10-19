import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct TherapyMilestoneRow: View {
    let milestone: TherapyMilestone

    private var category: TherapyCategory? {
        TherapyCategory.category(id: milestone.categoryID)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: category?.icon ?? "star.fill")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(category?.tint ?? AppTheme.accent)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    Text(LocalizedStringKey(milestone.categoryTitle))
                        .font(.caption.weight(.black))
                        .foregroundStyle(category?.tint ?? AppTheme.accent)

                    Spacer()

                    Text(milestone.date, style: .date)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Text(milestone.milestone)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.text)
                    .fixedSize(horizontal: false, vertical: true)

                Text(LocalizedStringKey(milestone.supportLevel))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                if !milestone.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(milestone.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(12)
        .background(AppTheme.fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

