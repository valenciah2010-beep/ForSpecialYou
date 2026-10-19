import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct AccidentLogEntrySheet: View {
    @Environment(\.dismiss) private var dismiss

    let option: QuickLogOption
    let onSave: (HealthLogEntry) -> Void

    @State private var timestamp = Date()
    @State private var selectedAccidentType = ""
    @State private var selectedContexts: Set<String> = []
    @State private var signaledBeforehand: Bool?
    @State private var notes = ""

    private let accidentTypes = ["Urine", "Stool", "Both"]
    private let contextOptions = [
        "🎯 Deep in Play",
        "🚌 On the Bus/Transition",
        "🏫 School/Therapy",
        "🛌 During Sleep"
    ]

    private var canSave: Bool {
        !selectedAccidentType.isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        accidentSectionCard(icon: "calendar.badge.clock", title: "Timestamp") {
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

                        accidentSectionCard(icon: "drop.triangle.fill", title: "Accident Type") {
                            HStack(spacing: 0) {
                                ForEach(accidentTypes, id: \.self) { type in
                                    Button {
                                        selectedAccidentType = selectedAccidentType == type ? "" : type
                                    } label: {
                                        Text(localizedAppString(type))
                                            .font(.subheadline.weight(.bold))
                                            .foregroundStyle(selectedAccidentType == type ? AppTheme.text : .secondary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 13)
                                            .background(selectedAccidentType == type ? Color(red: 0.78, green: 0.88, blue: 1.0) : AppTheme.fieldBackground)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }

                        accidentSectionCard(icon: "mappin.and.ellipse", title: "Context / Setting") {
                            FlowLayout(spacing: 8, rowSpacing: 8) {
                                ForEach(contextOptions, id: \.self) { context in
                                    accidentContextChip(context)
                                }
                            }
                        }

                        accidentSectionCard(icon: "figure.walk.motion", title: "Signaled Beforehand?") {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(localizedAppString("Did they signal or try to go?"))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)

                                HStack(spacing: 10) {
                                    accidentSignalButton(title: "Yes", value: true)
                                    accidentSignalButton(title: "No", value: false)
                                }
                            }
                        }

                        accidentSectionCard(icon: "note.text", title: "Notes") {
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

    private func accidentSectionCard<Content: View>(
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

    private func accidentContextChip(_ context: String) -> some View {
        let isSelected = selectedContexts.contains(context)

        return Button {
            if isSelected {
                selectedContexts.remove(context)
            } else {
                selectedContexts.insert(context)
            }
        } label: {
            Text(localizedAppString(context))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? AppTheme.text : .secondary)
                .padding(.horizontal, 13)
                .padding(.vertical, 10)
                .background(isSelected ? Color(red: 0.83, green: 0.76, blue: 0.95) : Color.gray.opacity(0.10))
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .stroke(isSelected ? Color(red: 0.68, green: 0.58, blue: 0.86).opacity(0.45) : Color.clear, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    private func accidentSignalButton(title: String, value: Bool) -> some View {
        let isSelected = signaledBeforehand == value

        return Button {
            signaledBeforehand = isSelected ? nil : value
        } label: {
            Text(localizedAppString(title))
                .font(.headline.weight(.bold))
                .foregroundStyle(isSelected ? .white : AppTheme.text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(isSelected ? option.tint : AppTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func save() {
        let contextText = selectedContexts.isEmpty
            ? localizedAppString("Not selected")
            : selectedContexts.sorted().map { localizedAppString($0) }.joined(separator: ", ")
        let signalText: String
        if let signaledBeforehand {
            signalText = signaledBeforehand ? localizedAppString("Yes") : localizedAppString("No")
        } else {
            signalText = localizedAppString("Not selected")
        }

        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let comments = [
            "Timestamp: \(localizedDateString(timestamp, dateStyle: .medium, timeStyle: .short))",
            "Accident Type: \(localizedAppString(selectedAccidentType))",
            "Context / Setting: \(contextText)",
            "Did they signal or try to go?: \(signalText)",
            trimmedNotes.isEmpty ? nil : "Notes: \(trimmedNotes)"
        ].compactMap { $0 }.joined(separator: "\n")

        let entry = HealthLogEntry(
            id: UUID(),
            type: .quickLog,
            categoryID: option.id,
            title: option.title,
            timestamp: timestamp,
            severity: 1,
            value: localizedAppString(selectedAccidentType),
            comments: comments
        )

        onSave(entry)
        dismiss()
    }
}

