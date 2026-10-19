import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct QuickLogSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedIDs: Set<String>

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(QuickLogOption.all) { option in
                        Button {
                            toggle(option)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: selectedIDs.contains(option.id) ? "checkmark.square.fill" : "square")
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(selectedIDs.contains(option.id) ? AppTheme.accent : .secondary)

                                Image(systemName: option.icon)
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(option.tint)
                                    .frame(width: 28)

                                Text(LocalizedStringKey(option.title))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.text)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(14)
                            .background(AppTheme.panel)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(18)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(localizedAppString("Quick Logs"))
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

    private func toggle(_ option: QuickLogOption) {
        var updatedSelection = selectedIDs

        if selectedIDs.contains(option.id) {
            updatedSelection.remove(option.id)
        } else {
            updatedSelection.insert(option.id)
        }

        selectedIDs = updatedSelection
    }
}

