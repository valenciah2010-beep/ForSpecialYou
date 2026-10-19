import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct DiagnosisSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedIDs: Set<String>

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(DiagnosisOption.all) { option in
                        diagnosisButton(option)
                    }
                }
                .padding(18)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(localizedAppString("Category"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(localizedAppString("Done")) {
                        dismiss()
                    }
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func diagnosisButton(_ option: DiagnosisOption) -> some View {
        let isSelected = selectedIDs.contains(option.id)

        return Button {
            if isSelected {
                selectedIDs.remove(option.id)
            } else {
                selectedIDs.insert(option.id)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isSelected ? AppTheme.accent : .secondary.opacity(0.75))

                Text(option.emoji)
                    .font(.title3)
                    .frame(width: 30)

                Text(localizedAppString(option.title))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
            .background(isSelected ? AppTheme.accent.opacity(0.12) : AppTheme.panel)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? AppTheme.accent.opacity(0.32) : Color.clear, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

