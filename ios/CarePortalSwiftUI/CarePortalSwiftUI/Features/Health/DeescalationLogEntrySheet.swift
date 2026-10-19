import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct DeescalationLogEntrySheet: View {
    @Environment(\.dismiss) private var dismiss

    let option: QuickLogOption
    let onSave: (HealthLogEntry) -> Void

    @State private var timestamp = Date()
    @State private var selectedTools: Set<String> = []
    @State private var selectedEffectiveness = ""
    @State private var selectedBaselineTime = ""
    @State private var notes = ""

    private let toolOptions = [
        "🎧 Headphones",
        "🧱 Deep Pressure",
        "💡 Dimmed Lights",
        "🛏️ Weighted Blanket",
        "🔄 Redirection/Distraction",
        "🧘 Quiet Space"
    ]

    private let effectivenessOptions = [
        "Not Effective",
        "Somewhat Effective",
        "Highly Effective"
    ]

    private let baselineOptions = [
        "<5 mins",
        "5-15 mins",
        "15-30 mins",
        "30+ mins"
    ]

    private var canSave: Bool {
        !selectedEffectiveness.isEmpty || !selectedTools.isEmpty || !selectedBaselineTime.isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        deescalationSectionCard(icon: "calendar.badge.clock", title: "Timestamp") {
                            HStack(spacing: 10) {
                                DatePicker("", selection: $timestamp, displayedComponents: .date)
                                    .labelsHidden()
                                    .datePickerStyle(.compact)

                                DatePicker("", selection: $timestamp, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .datePickerStyle(.compact)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        deescalationSectionCard(icon: "hands.sparkles", title: "Tools Used") {
                            FlowLayout(spacing: 8, rowSpacing: 8) {
                                ForEach(toolOptions, id: \.self) { tool in
                                    deescalationToolChip(tool)
                                }
                            }
                        }

                        deescalationSectionCard(icon: "gauge.with.dots.needle.bottom.50percent", title: "Effectiveness") {
                            HStack(spacing: 0) {
                                ForEach(effectivenessOptions, id: \.self) { effectiveness in
                                    Button {
                                        selectedEffectiveness = selectedEffectiveness == effectiveness ? "" : effectiveness
                                    } label: {
                                        Text(localizedAppString(effectiveness))
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(selectedEffectiveness == effectiveness ? AppTheme.text : .secondary)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                            .minimumScaleFactor(0.82)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 13)
                                            .padding(.horizontal, 4)
                                            .background(selectedEffectiveness == effectiveness ? effectivenessColor(for: effectiveness) : AppTheme.fieldBackground)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }

                        deescalationSectionCard(icon: "clock", title: "Time to Baseline") {
                            HStack(spacing: 8) {
                                ForEach(baselineOptions, id: \.self) { time in
                                    Button {
                                        selectedBaselineTime = selectedBaselineTime == time ? "" : time
                                    } label: {
                                        Text(localizedAppString(time))
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(selectedBaselineTime == time ? .white : AppTheme.text)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(selectedBaselineTime == time ? option.tint : AppTheme.fieldBackground)
                                            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        deescalationSectionCard(icon: "note.text", title: "Notes") {
                            TextField(localizedAppString("Add details, context, or follow-up notes"), text: $notes, axis: .vertical)
                                .textInputAutocapitalization(.sentences)
                                .lineLimit(3...6)
                                .padding(12)
                                .background(AppTheme.fieldBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                    .padding(18)
                }

                StickyBottomSaveButton(
                    title: "Save Log",
                    tint: option.tint,
                    isDisabled: !canSave
                ) {
                    save()
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    ModalToolbarTitle(icon: option.icon, title: option.title, tint: option.tint)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    ToolbarCloseButton {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
    }

    private func deescalationSectionCard<Content: View>(
        icon: String,
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(option.tint)
                    .frame(width: 30, height: 30)
                    .background(option.tint.opacity(0.12))
                    .clipShape(Circle())

                Text(localizedAppString(title))
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.text)
            }

            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.035), radius: 10, x: 0, y: 5)
    }

    private func deescalationToolChip(_ tool: String) -> some View {
        let isSelected = selectedTools.contains(tool)

        return Button {
            if isSelected {
                selectedTools.remove(tool)
            } else {
                selectedTools.insert(tool)
            }
        } label: {
            Text(localizedAppString(tool))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? AppTheme.text : .secondary)
                .padding(.horizontal, 13)
                .padding(.vertical, 10)
                .background(isSelected ? Color(red: 0.78, green: 0.88, blue: 1.0) : Color.gray.opacity(0.10))
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .stroke(isSelected ? Color(red: 0.48, green: 0.66, blue: 0.90).opacity(0.45) : Color.clear, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    private func effectivenessColor(for effectiveness: String) -> Color {
        switch effectiveness {
        case "Not Effective":
            return Color.gray.opacity(0.22)
        case "Somewhat Effective":
            return Color(red: 1.0, green: 0.86, blue: 0.52)
        case "Highly Effective":
            return Color(red: 0.70, green: 0.88, blue: 0.70)
        default:
            return AppTheme.fieldBackground
        }
    }

    private func save() {
        let toolsText = selectedTools.isEmpty
            ? localizedAppString("Not selected")
            : selectedTools.sorted().map { localizedAppString($0) }.joined(separator: ", ")
        let effectivenessText = selectedEffectiveness.isEmpty
            ? localizedAppString("Not selected")
            : localizedAppString(selectedEffectiveness)
        let baselineText = selectedBaselineTime.isEmpty
            ? localizedAppString("Not selected")
            : localizedAppString(selectedBaselineTime)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let comments = [
            "Timestamp: \(localizedDateString(timestamp, dateStyle: .medium, timeStyle: .short))",
            "Tools Used: \(toolsText)",
            "Effectiveness: \(effectivenessText)",
            "Time to Baseline: \(baselineText)",
            trimmedNotes.isEmpty ? nil : "Notes: \(trimmedNotes)"
        ].compactMap { $0 }.joined(separator: "\n")

        let entry = HealthLogEntry(
            id: UUID(),
            type: .quickLog,
            categoryID: option.id,
            title: option.title,
            timestamp: timestamp,
            severity: selectedEffectiveness == "Highly Effective" ? 1 : selectedEffectiveness == "Somewhat Effective" ? 3 : 5,
            value: effectivenessText,
            comments: comments
        )

        onSave(entry)
        dismiss()
    }
}

