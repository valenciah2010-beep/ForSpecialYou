import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct HealthLogEntrySheet: View {
    @Environment(\.dismiss) private var dismiss

    let target: HealthLogInputTarget
    let onSave: (HealthLogEntry) -> Void

    @State private var useCurrentTime = true
    @State private var timestamp = Date()
    @State private var severity = 3.0
    @State private var value = ""
    @State private var comments = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 14) {
                            Toggle("Use current time", isOn: $useCurrentTime)
                                .font(.subheadline.weight(.semibold))
                                .tint(AppTheme.accent)

                            DatePicker(
                                "Time",
                                selection: $timestamp,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .disabled(useCurrentTime)
                            .opacity(useCurrentTime ? 0.55 : 1)

                            VStack(alignment: .leading, spacing: 8) {
                                Text(LocalizedStringKey(target.valuePrompt))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.text)

                                TextField(
                                    target.logType == .quickLog
                                        ? localizedAppString("Short note")
                                        : localizedAppString("Example: 7 hours, normal, 2/5"),
                                    text: $value
                                )
                                .textInputAutocapitalization(.never)
                                .padding(12)
                                .background(AppTheme.fieldBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("\(localizedAppString("Severity")): \(Int(severity))/5")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.text)

                                Slider(value: $severity, in: 1...5, step: 1)
                                    .tint(target.tint)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text(localizedAppString("Comments"))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.text)

                                TextField(localizedAppString("Add details, context, triggers, or what helped"), text: $comments, axis: .vertical)
                                    .textInputAutocapitalization(.never)
                                    .lineLimit(4...7)
                                    .padding(12)
                                    .background(AppTheme.fieldBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                        .authPanel()
                    }
                    .padding(18)
                }
                StickyBottomSaveButton(title: "Save Log", tint: AppTheme.accent) {
                    save()
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ToolbarCloseButton {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .principal) {
                    ModalToolbarTitle(icon: target.icon, title: target.title, tint: target.tint)
                }

            }
        }
        .presentationDetents([.large])
        .onAppear {
            value = target.logType == .snapshot ? "" : target.title
        }
    }

    private func save() {
        let entry = HealthLogEntry(
            id: UUID(),
            type: target.logType,
            categoryID: target.categoryID,
            title: target.title,
            timestamp: useCurrentTime ? Date() : timestamp,
            severity: Int(severity),
            value: value.trimmingCharacters(in: .whitespacesAndNewlines),
            comments: comments.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        onSave(entry)
        dismiss()
    }
}

