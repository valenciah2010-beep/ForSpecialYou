import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct TherapyMilestoneSheet: View {
    @Environment(\.dismiss) private var dismiss

    let category: TherapyCategory
    let onSave: (TherapyMilestone) -> Void

    @State private var date = Date()
    @State private var milestone = ""
    @State private var supportLevel = "With full support"
    @State private var notes = ""

    private let supportLevels = [
        "With full support",
        "With some support",
        "With a prompt",
        "Mostly independent",
        "Independent"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 12) {
                            Image(systemName: category.icon)
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(category.tint)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 3) {
                                Text(LocalizedStringKey(category.title))
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(AppTheme.text)

                                Text(localizedAppString("Log a new milestone"))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }

                        DatePicker(localizedAppString("Date"), selection: $date, displayedComponents: .date)
                            .font(.subheadline.weight(.semibold))
                            .padding(12)
                            .background(AppTheme.fieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        ProfileTextField(
                            title: "Milestone",
                            text: $milestone,
                            placeholder: "Example: Used two-word request",
                            axis: .vertical
                        )

                        VStack(alignment: .leading, spacing: 8) {
                            Text(localizedAppString("Support level"))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.text)

                            Picker(localizedAppString("Support level"), selection: $supportLevel) {
                                ForEach(supportLevels, id: \.self) { level in
                                    Text(LocalizedStringKey(level)).tag(level)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(AppTheme.fieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        ProfileTextField(
                            title: "Notes",
                            text: $notes,
                            placeholder: "What helped, where it happened, or what to practice next",
                            axis: .vertical
                        )
                    }
                    .padding(20)
                }

                StickyBottomSaveButton(
                    title: "Save",
                    tint: category.tint,
                    isDisabled: milestone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ) {
                    save()
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(localizedAppString("Milestone"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ToolbarCloseButton {
                        dismiss()
                    }
                }
            }
        }
    }

    private func save() {
        let trimmedMilestone = milestone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMilestone.isEmpty else { return }

        onSave(
            TherapyMilestone(
                categoryID: category.id,
                categoryTitle: category.title,
                date: date,
                milestone: trimmedMilestone,
                supportLevel: supportLevel,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        )
        dismiss()
    }
}

