import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct MeasurementSnapshotSheet: View {
    @Environment(\.dismiss) private var dismiss

    let target: MeasurementSnapshotEditorTarget
    let onSave: (HealthLogEntry) -> Void

    @State private var timestamp: Date
    @State private var measurementValue: String
    @State private var selectedUnit: String
    @State private var notes: String

    private var units: [String] {
        target.option.id == "height" ? ["cm", "in"] : ["Kg", "lbs"]
    }

    private var canSave: Bool {
        !measurementValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(target: MeasurementSnapshotEditorTarget, onSave: @escaping (HealthLogEntry) -> Void) {
        self.target = target
        self.onSave = onSave

        let parsed = Self.parseMeasurementValue(
            target.existingEntry?.value ?? "",
            defaultUnit: target.option.id == "height" ? "cm" : "Kg"
        )
        self._timestamp = State(initialValue: target.existingEntry?.timestamp ?? Date())
        self._measurementValue = State(initialValue: parsed.value)
        self._selectedUnit = State(initialValue: parsed.unit)
        self._notes = State(initialValue: target.existingEntry?.comments ?? "")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                Text(localizedAppString("Measurement time"))
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(AppTheme.text)

                                Spacer()

                                DatePicker(localizedAppString("Measurement time"), selection: $timestamp, displayedComponents: [.date, .hourAndMinute])
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                            }
                            .padding(14)
                            .background(AppTheme.fieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .authPanel()

                        VStack(alignment: .leading, spacing: 12) {
                            CyclicVomitingMeasurementField(
                                title: target.option.title,
                                units: units,
                                text: $measurementValue,
                                selectedUnit: $selectedUnit
                            )
                        }
                        .authPanel()

                        VStack(alignment: .leading, spacing: 10) {
                            Text(localizedAppString("Notes"))
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.text)

                            TextField(localizedAppString("Add measurement notes"), text: $notes, axis: .vertical)
                                .textInputAutocapitalization(.sentences)
                                .lineLimit(3...6)
                                .padding(14)
                                .background(AppTheme.fieldBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .authPanel()
                    }
                    .padding(18)
                }

                StickyBottomSaveButton(title: "Save", tint: target.option.tint, isDisabled: !canSave) {
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
                    ModalToolbarTitle(icon: target.option.icon, title: target.option.title, tint: target.option.tint)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func save() {
        let value = "\(measurementValue.trimmingCharacters(in: .whitespacesAndNewlines)) \(selectedUnit)"
        let entry = HealthLogEntry(
            id: UUID(),
            type: .snapshot,
            categoryID: target.option.id,
            title: target.option.title,
            timestamp: timestamp,
            severity: 1,
            value: value,
            comments: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        onSave(entry)
        dismiss()
    }

    private static func parseMeasurementValue(_ value: String, defaultUnit: String) -> (value: String, unit: String) {
        let pieces = value.split(separator: " ").map(String.init)
        guard let first = pieces.first else {
            return ("", defaultUnit)
        }

        return (first, pieces.dropFirst().first ?? defaultUnit)
    }
}

