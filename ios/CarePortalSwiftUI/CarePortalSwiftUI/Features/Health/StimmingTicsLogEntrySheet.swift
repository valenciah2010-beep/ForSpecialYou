import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct StimmingTicsLogEntrySheet: View {
    @Environment(\.dismiss) private var dismiss

    let option: QuickLogOption
    let onSave: (HealthLogEntry) -> Void

    @State private var timestamp = Date()
    @State private var selectedBehaviorTypes: Set<String> = []
    @State private var selectedFrequency = ""
    @State private var stateValue = 0.0
    @State private var selectedContexts: Set<String> = []

    private let behaviorOptions = [
        "Hand Flapping",
        "Vocal Tics/Sounds",
        "Rocking",
        "Pacing",
        "Eye Blinking",
        "Head Shaking",
        "Repetitive Phrases"
    ]

    private let frequencyOptions = [
        "Low (Occasional)",
        "Medium (Frequent)",
        "High (Constant)"
    ]

    private let contextOptions = [
        "School/Therapy",
        "Screen Time",
        "Transitioning",
        "Public Place",
        "Relaxing at Home"
    ]

    private var apparentStateText: String {
        stateValue < 0.5 ? "Joyful/Regulating (Happy)" : "Anxious/Stressed"
    }

    private var severityFromFrequency: Int {
        switch selectedFrequency {
        case "High (Constant)":
            return 5
        case "Medium (Frequent)":
            return 3
        case "Low (Occasional)":
            return 1
        default:
            return stateValue < 0.5 ? 2 : 4
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 14) {
                        DatePicker(
                            localizedAppString("Timestamp"),
                            selection: $timestamp,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .font(.subheadline.weight(.semibold))

                        stimmingMultiSelectSection(
                            title: "Behavior Type",
                            options: behaviorOptions,
                            selection: $selectedBehaviorTypes
                        )

                        stimmingFrequencySection

                        apparentStateSection

                        stimmingMultiSelectSection(
                            title: "Context/Setting",
                            options: contextOptions,
                            selection: $selectedContexts
                        )
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

    private var stimmingFrequencySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(localizedAppString("Frequency"))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.text)

            VStack(spacing: 8) {
                ForEach(frequencyOptions, id: \.self) { frequency in
                    Button {
                        selectedFrequency = selectedFrequency == frequency ? "" : frequency
                    } label: {
                        HStack {
                            Text(localizedAppString(frequency))
                                .font(.headline.weight(.bold))
                                .foregroundStyle(selectedFrequency == frequency ? .white : AppTheme.text)

                            Spacer()

                            Image(systemName: selectedFrequency == frequency ? "checkmark.circle.fill" : "circle")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(selectedFrequency == frequency ? .white : .secondary.opacity(0.65))
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity)
                        .background(selectedFrequency == frequency ? option.tint : AppTheme.fieldBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var apparentStateSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(localizedAppString("Apparent State"))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.text)

                Spacer()

                Text(localizedAppString(apparentStateText))
                    .font(.caption.weight(.black))
                    .foregroundStyle(option.tint)
            }

            Picker(localizedAppString("Apparent State"), selection: $stateValue) {
                Text(localizedAppString("Joyful/Regulating (Happy)")).tag(0.0)
                Text(localizedAppString("Anxious/Stressed")).tag(1.0)
            }
            .pickerStyle(.segmented)
        }
    }

    private func stimmingMultiSelectSection(
        title: String,
        options: [String],
        selection: Binding<Set<String>>
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(localizedAppString(title))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.text)

            FlowLayout(spacing: 8, rowSpacing: 8) {
                ForEach(options, id: \.self) { chip in
                    CyclicVomitingOptionChip(
                        title: chip,
                        isSelected: selection.wrappedValue.contains(chip),
                        tint: option.tint
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

    private func save() {
        let behaviorText = selectedBehaviorTypes.isEmpty
            ? localizedAppString("Not selected")
            : selectedBehaviorTypes.sorted().map { localizedAppString($0) }.joined(separator: ", ")
        let frequencyText = selectedFrequency.isEmpty ? localizedAppString("Not selected") : localizedAppString(selectedFrequency)
        let contextText = selectedContexts.isEmpty
            ? localizedAppString("Not selected")
            : selectedContexts.sorted().map { localizedAppString($0) }.joined(separator: ", ")
        let apparentState = localizedAppString(apparentStateText)

        let comments = [
            "Timestamp: \(localizedDateString(timestamp, dateStyle: .medium, timeStyle: .short))",
            "Behavior Type: \(behaviorText)",
            "Frequency: \(frequencyText)",
            "Apparent State: \(apparentState)",
            "Context/Setting: \(contextText)"
        ].joined(separator: "\n")

        let entry = HealthLogEntry(
            id: UUID(),
            type: .quickLog,
            categoryID: option.id,
            title: option.title,
            timestamp: timestamp,
            severity: severityFromFrequency,
            value: "\(localizedAppString("Stimming/Tics")) · \(frequencyText)",
            comments: comments
        )

        onSave(entry)
        dismiss()
    }
}

