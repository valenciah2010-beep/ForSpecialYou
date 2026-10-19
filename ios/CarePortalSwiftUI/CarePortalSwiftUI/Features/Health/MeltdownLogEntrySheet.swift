import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct MeltdownLogEntrySheet: View {
    @Environment(\.dismiss) private var dismiss

    let option: QuickLogOption
    let onSave: (HealthLogEntry) -> Void

    @State private var timestamp = Date()
    @State private var intensity = 3.0
    @State private var selectedTriggers: Set<String> = []
    @State private var selectedDuration = ""
    @State private var selectedCalmingTools: Set<String> = []
    @State private var notes = ""

    private let triggerOptions = [
        "Loud Noise",
        "Crowds",
        "Transitioning",
        "Hunger",
        "Fatigue",
        "Unknown"
    ]

    private let durationOptions = [
        "<5 mins",
        "5-15 mins",
        "15-30 mins",
        "30+ mins"
    ]

    private let calmingToolOptions = [
        "Deep Pressure",
        "Headphones",
        "Dim Lights",
        "Weighted Blanket",
        "Redirection"
    ]

    private var intensityDescription: String {
        switch Int(intensity) {
        case 1:
            return "Mild Agitation/Crying"
        case 2:
            return "Low Distress"
        case 3:
            return "Moderate Meltdown"
        case 4:
            return "High Distress"
        default:
            return "Severe Meltdown/Safety Risk"
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        meltdownHeader

                        timestampCard

                        intensityCard

                        meltdownMultiSelectSection(
                            icon: "exclamationmark.triangle",
                            title: "Triggers",
                            options: triggerOptions,
                            selection: $selectedTriggers
                        )

                        meltdownSingleSelectSection(
                            icon: "clock",
                            title: "Duration",
                            options: durationOptions,
                            selection: $selectedDuration
                        )

                        meltdownMultiSelectSection(
                            icon: "heart.circle",
                            title: "Calming Tools Tried",
                            options: calmingToolOptions,
                            selection: $selectedCalmingTools
                        )

                        notesCard
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
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationDetents([.large])
    }

    private var meltdownHeader: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(option.tint.opacity(0.18))
                    .frame(width: 52, height: 52)

                Image(systemName: option.icon)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(option.tint)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(localizedAppString("Log Meltdown"))
                    .font(.title.weight(.black))
                    .foregroundStyle(AppTheme.text)

                Text(localizedAppString("Track and understand what happened."))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.fieldBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(localizedAppString("Close"))
        }
        .padding(.top, 2)
    }

    private var timestampCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "calendar.badge.clock")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 30, height: 30)
                .background(AppTheme.accent.opacity(0.1))
                .clipShape(Circle())

            Text(localizedAppString("Timestamp"))
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 4)

            DatePicker("", selection: $timestamp, displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(.compact)
                .fixedSize()

            DatePicker("", selection: $timestamp, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .datePickerStyle(.compact)
                .fixedSize()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.035), radius: 10, x: 0, y: 5)
    }

    private var intensityCard: some View {
        meltdownSectionCard(icon: "waveform.path.ecg", title: "Intensity") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(localizedAppString("How intense was it?"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(Int(intensity))/5")
                        .font(.headline.weight(.black))
                        .foregroundStyle(option.tint)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(option.tint.opacity(0.12))
                        .overlay {
                            Capsule()
                                .stroke(option.tint.opacity(0.45), lineWidth: 1)
                        }
                        .clipShape(Capsule())
                }

                Slider(value: $intensity, in: 1...5, step: 1)
                    .tint(option.tint)
                    .padding(.vertical, 2)

                Text(localizedAppString(intensityDescription))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(option.tint)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 7)
                    .background(option.tint.opacity(0.12))
                    .clipShape(Capsule())
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private var notesCard: some View {
        meltdownSectionCard(icon: "note.text", title: "Notes") {
            TextField(localizedAppString("Add any additional details about what happened..."), text: $notes, axis: .vertical)
                .textInputAutocapitalization(.sentences)
                .lineLimit(3...6)
                .padding(12)
                .background(AppTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func meltdownSectionCard<Content: View>(
        icon: String,
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 30, height: 30)
                    .background(AppTheme.accent.opacity(0.1))
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

    private func meltdownMultiSelectSection(
        icon: String,
        title: String,
        options: [String],
        selection: Binding<Set<String>>
    ) -> some View {
        meltdownSectionCard(icon: icon, title: title) {
            FlowLayout(spacing: 8, rowSpacing: 8) {
                ForEach(options, id: \.self) { chip in
                    meltdownOptionChip(
                        title: chip,
                        icon: meltdownOptionIcon(for: chip),
                        isSelected: selection.wrappedValue.contains(chip),
                        allowsCheckmark: true
                    ) {
                        if selection.wrappedValue.contains(chip) {
                            selection.wrappedValue.remove(chip)
                        } else {
                            selection.wrappedValue.insert(chip)
                        }
                    }
                }
            }
        }
    }

    private func meltdownSingleSelectSection(
        icon: String,
        title: String,
        options: [String],
        selection: Binding<String>
    ) -> some View {
        meltdownSectionCard(icon: icon, title: title) {
            FlowLayout(spacing: 8, rowSpacing: 8) {
                ForEach(options, id: \.self) { chip in
                    meltdownOptionChip(
                        title: chip,
                        icon: "clock",
                        isSelected: selection.wrappedValue == chip,
                        allowsCheckmark: false
                    ) {
                        selection.wrappedValue = selection.wrappedValue == chip ? "" : chip
                    }
                }
            }
        }
    }

    private func meltdownOptionChip(
        title: String,
        icon: String,
        isSelected: Bool,
        allowsCheckmark: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(isSelected ? AppTheme.accent : AppTheme.accent.opacity(0.9))

                Text(localizedAppString(title))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? AppTheme.accent : AppTheme.text)

                if allowsCheckmark {
                    Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(isSelected ? AppTheme.accent : .secondary.opacity(0.55))
                }
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 11)
            .background(isSelected ? AppTheme.accent.opacity(0.12) : Color.white)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(isSelected ? AppTheme.accent.opacity(0.55) : Color.black.opacity(0.08), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private func meltdownOptionIcon(for option: String) -> String {
        switch option {
        case "Loud Noise":
            return "speaker.wave.2"
        case "Crowds":
            return "person.2"
        case "Transitioning":
            return "arrow.triangle.2.circlepath"
        case "Hunger":
            return "fork.knife"
        case "Fatigue":
            return "moon.zzz"
        case "Unknown":
            return "questionmark.circle"
        case "Deep Pressure":
            return "hands.sparkles"
        case "Headphones":
            return "headphones"
        case "Dim Lights":
            return "lightbulb"
        case "Weighted Blanket":
            return "rectangle.fill.on.rectangle.fill"
        case "Redirection":
            return "arrow.uturn.left"
        default:
            return "circle"
        }
    }

    private func save() {
        let durationText = selectedDuration.isEmpty ? localizedAppString("Not selected") : localizedAppString(selectedDuration)
        let triggersText = selectedTriggers.isEmpty
            ? localizedAppString("Not selected")
            : selectedTriggers.sorted().map { localizedAppString($0) }.joined(separator: ", ")
        let toolsText = selectedCalmingTools.isEmpty
            ? localizedAppString("Not selected")
            : selectedCalmingTools.sorted().map { localizedAppString($0) }.joined(separator: ", ")
        let intensityText = "\(Int(intensity))/5 - \(localizedAppString(intensityDescription))"
        let comments = [
            "Timestamp: \(localizedDateString(timestamp, dateStyle: .medium, timeStyle: .short))",
            "Intensity: \(intensityText)",
            "Triggers: \(triggersText)",
            "Duration: \(durationText)",
            "Calming Tools Tried: \(toolsText)",
            notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? nil
                : "Notes: \(notes.trimmingCharacters(in: .whitespacesAndNewlines))"
        ].compactMap { $0 }.joined(separator: "\n")

        let entry = HealthLogEntry(
            id: UUID(),
            type: .quickLog,
            categoryID: option.id,
            title: option.title,
            timestamp: timestamp,
            severity: Int(intensity),
            value: "\(localizedAppString("Meltdown")) · \(durationText)",
            comments: comments
        )

        onSave(entry)
        dismiss()
    }
}

