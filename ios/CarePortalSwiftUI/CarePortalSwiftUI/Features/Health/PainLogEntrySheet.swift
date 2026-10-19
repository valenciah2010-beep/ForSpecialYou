import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct PainLogEntrySheet: View {
    @Environment(\.dismiss) private var dismiss

    let option: QuickLogOption
    let onSave: (HealthLogEntry) -> Void

    @State private var severity = 3.0
    @State private var painPoints: [PainPoint] = []
    @State private var shortComment = ""
    @State private var indicators = ""

    private var displayLocation: String {
        painPoints.isEmpty ? localizedAppString("Tap the body to add a pain dot") : String(format: localizedAppString("%d pain location(s)"), painPoints.count)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 16) {
                            PainBodySelector(
                                painPoints: $painPoints,
                                tint: option.tint
                            )

                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(localizedAppString("Severity")): \(Int(severity))/5")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.text)

                            Slider(value: $severity, in: 1...5, step: 1)
                                .tint(option.tint)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text(localizedAppString("Short Comment"))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.text)

                            TextField(localizedAppString("What happened or what helped?"), text: $shortComment, axis: .vertical)
                                .textInputAutocapitalization(.never)
                                .lineLimit(3...5)
                                .padding(12)
                                .background(AppTheme.fieldBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text(localizedAppString("Indicators"))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.text)

                            TextField(localizedAppString("Crying, holding head, aggression, guarding, limping"), text: $indicators, axis: .vertical)
                                .textInputAutocapitalization(.never)
                                .lineLimit(3...6)
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
                    ModalToolbarTitle(icon: option.icon, title: option.title, tint: option.tint)
                }

            }
        }
        .presentationDetents([.large])
    }

    private func save() {
        let savedLocation = painPoints.isEmpty
            ? "Pain location not selected"
            : painPoints
                .map { "\($0.side.rawValue): \(Int($0.x * 100))%, \(Int($0.y * 100))%" }
                .joined(separator: "; ")
        let notes = [
            shortComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : "Comment: \(shortComment.trimmingCharacters(in: .whitespacesAndNewlines))",
            indicators.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : "Indicators: \(indicators.trimmingCharacters(in: .whitespacesAndNewlines))"
        ]
        .compactMap { $0 }
        .joined(separator: "\n\n")

        let entry = HealthLogEntry(
            id: UUID(),
            type: .quickLog,
            categoryID: option.id,
            title: option.title,
            timestamp: Date(),
            severity: Int(severity),
            value: savedLocation,
            comments: notes
        )
        onSave(entry)
        dismiss()
    }
}

