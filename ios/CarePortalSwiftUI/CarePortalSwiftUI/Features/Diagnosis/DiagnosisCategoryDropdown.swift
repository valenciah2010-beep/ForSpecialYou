import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct DiagnosisCategoryDropdown: View {
    @Binding var selectedCategoryIDs: Set<String>
    @Binding var isExpanded: Bool

    private var selectedCategoryText: String {
        let selected = DiagnosisOption.all
            .filter { selectedCategoryIDs.contains($0.id) }
            .map { "\($0.emoji) \(localizedAppString($0.title))" }

        return selected.isEmpty ? localizedAppString("Select category") : selected.joined(separator: ", ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.86)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(localizedAppString("Select category"))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)

                        Text(selectedCategoryText)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(AppTheme.text)
                            .lineLimit(2)
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(14)
                .background(AppTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(DiagnosisOption.all) { option in
                        Button {
                            toggle(option.id)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: selectedCategoryIDs.contains(option.id) ? "checkmark.square.fill" : "square")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(selectedCategoryIDs.contains(option.id) ? AppTheme.accent : .secondary)

                                Text(option.emoji)
                                    .font(.title3)
                                    .frame(width: 28)

                                Text(localizedAppString(option.title))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.text)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)

                                Spacer()
                            }
                            .padding(12)
                            .background(selectedCategoryIDs.contains(option.id) ? AppTheme.accent.opacity(0.10) : AppTheme.panel)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func toggle(_ id: String) {
        if selectedCategoryIDs.contains(id) {
            selectedCategoryIDs.remove(id)
        } else {
            selectedCategoryIDs.insert(id)
        }
    }
}

