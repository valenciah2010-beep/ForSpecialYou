import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct DiagnosisCategoryTimelineView: View {
    let items: [DiagnosisCategoryTimelineItem]
    let onSelect: (DiagnosisCategoryTimelineItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(localizedAppString("History"))
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.text)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    Button {
                        onSelect(item)
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            VStack(spacing: 0) {
                                ZStack {
                                    Circle()
                                        .fill(item.tint.opacity(0.16))
                                        .frame(width: 34, height: 34)

                                    Image(systemName: item.icon)
                                        .font(.caption.weight(.black))
                                        .foregroundStyle(item.tint)
                                }

                                if index < items.count - 1 {
                                    Rectangle()
                                        .fill(AppTheme.accent.opacity(0.14))
                                        .frame(width: 2, height: 56)
                                }
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                HStack(alignment: .top, spacing: 8) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(item.title)
                                            .font(.headline.weight(.bold))
                                            .foregroundStyle(AppTheme.text)
                                            .lineLimit(2)

                                        Text(localizedDateString(item.date, dateStyle: .medium, timeStyle: .none))
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                    Text(item.kindTitle)
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(item.tint)
                                        .padding(.horizontal, 9)
                                        .padding(.vertical, 4)
                                        .background(item.tint.opacity(0.12))
                                        .clipShape(Capsule())
                                }

                                if !item.notePreview.isEmpty {
                                    Text(item.notePreview)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            .padding(.top, 5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.bottom, index < items.count - 1 ? 4 : 0)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .diagnosisDetailCard()
    }
}

