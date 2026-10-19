import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct SeizureTimerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let option: QuickLogOption
    let initialSeizureType: String
    let onSave: (HealthLogEntry) -> Void

    @State private var startTime = Date()
    @State private var elapsedSeconds = 0
    @State private var isRunning = true
    @State private var isStopped = false
    @State private var severity = 3.0
    @State private var seizureType = "Seizure Type"
    @State private var triggers = ""
    @State private var postEventNotes = ""
    @State private var showingDeleteConfirmation = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let seizureTypes = [
        "Seizure Type",
        "Focal",
        "Absence",
        "Tonic-clonic",
        "Atonic",
        "Myoclonic",
        "Infantile spasm",
        "Other"
    ]

    private var defaultSeizureType: String {
        seizureTypes.contains(initialSeizureType) ? initialSeizureType : "Seizure Type"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(spacing: 12) {
                            Image(systemName: option.icon)
                                .font(.system(size: 34, weight: .bold))
                                .foregroundStyle(option.tint)
                                .frame(width: 70, height: 70)
                                .background(option.tint.opacity(0.16))
                                .clipShape(Circle())

                            Text(durationText(elapsedSeconds))
                                .font(.system(size: 48, weight: .black, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(AppTheme.text)

                            Text(LocalizedStringKey(isStopped ? "Timer stopped" : (isRunning ? "Timer running" : "Timer paused")))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(18)
                        .background(AppTheme.panel)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                        HStack(spacing: 12) {
                            Button {
                                isRunning.toggle()
                            } label: {
                                Text(LocalizedStringKey(isRunning ? "Pause" : "Resume"))
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(AppTheme.accent)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(AppTheme.accent.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .disabled(isStopped)

                            Button {
                                isRunning = false
                                isStopped = true
                            } label: {
                                Text(localizedAppString("Stop"))
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .disabled(isStopped)
                        }

                        if !isStopped {
                            Button {
                                skipTimer()
                            } label: {
                                Text(localizedAppString("Skip"))
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(AppTheme.accent)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(AppTheme.fieldBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }

                        if isStopped {
                            VStack(alignment: .leading, spacing: 16) {
                                Text(localizedAppString("Seizure Details"))
                                    .font(.headline.weight(.bold))

                                VStack(alignment: .leading, spacing: 10) {
                                    Text(localizedAppString("Duration"))
                                        .font(.subheadline.weight(.semibold))

                                    HStack(spacing: 10) {
                                        DurationNumberField(title: localizedAppString("Minutes"), value: durationMinutesBinding)
                                        DurationNumberField(title: localizedAppString("Seconds"), value: durationSecondsBinding)
                                    }

                                    Stepper("\(localizedAppString("Fine tune")): \(durationText(elapsedSeconds))", value: $elapsedSeconds, in: 0...7200, step: 1)
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                }

                                Picker(localizedAppString("Seizure Type"), selection: $seizureType) {
                                    ForEach(seizureTypes, id: \.self) { type in
                                        Text(LocalizedStringKey(type)).tag(type)
                                    }
                                }
                                .pickerStyle(.menu)

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("\(localizedAppString("Severity")): \(Int(severity))/5")
                                        .font(.subheadline.weight(.semibold))
                                    Slider(value: $severity, in: 1...5, step: 1)
                                        .tint(option.tint)
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text(localizedAppString("Triggers"))
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(AppTheme.text)

                                    TextField(localizedAppString("Flashing lights, missed sleep, heat, illness, etc."), text: $triggers, axis: .vertical)
                                        .textInputAutocapitalization(.never)
                                        .lineLimit(3...6)
                                        .padding(12)
                                        .background(AppTheme.fieldBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text(localizedAppString("Post-event Notes"))
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(AppTheme.text)

                                    TextField(localizedAppString("Recovery, breathing, color, awareness, what helped"), text: $postEventNotes, axis: .vertical)
                                        .textInputAutocapitalization(.never)
                                        .lineLimit(4...7)
                                        .padding(12)
                                        .background(AppTheme.fieldBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }

                                Button(role: .destructive) {
                                    showingDeleteConfirmation = true
                                } label: {
                                    Text(localizedAppString("Delete"))
                                        .font(.headline.weight(.bold))
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.red.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                            }
                            .authPanel()
                        }
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
                        if isStopped {
                            showingDeleteConfirmation = true
                        } else {
                            dismiss()
                        }
                    }
                }

                ToolbarItem(placement: .principal) {
                    ModalToolbarTitle(icon: option.icon, title: option.title, tint: option.tint)
                }

            }
            .confirmationDialog(
                localizedAppString("Delete this seizure timer?"),
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(localizedAppString("Delete Timer"), role: .destructive) {
                    dismiss()
                }
                Button(localizedAppString("Keep Editing"), role: .cancel) {
                }
            } message: {
                Text(localizedAppString("This timer has not been saved."))
            }
        }
        .presentationDetents([.large])
        .onReceive(timer) { _ in
            guard isRunning, !isStopped else { return }
            elapsedSeconds += 1
        }
        .onAppear {
            startTime = Date()
            elapsedSeconds = 0
            isRunning = true
            isStopped = false
            seizureType = defaultSeizureType
        }
    }

    private func skipTimer() {
        elapsedSeconds = 0
        isRunning = false
        isStopped = true
    }

    private var durationMinutesBinding: Binding<Int> {
        Binding(
            get: { elapsedSeconds / 60 },
            set: { newValue in
                let minutes = min(max(newValue, 0), 120)
                elapsedSeconds = min((minutes * 60) + durationSecondsBinding.wrappedValue, 7200)
            }
        )
    }

    private var durationSecondsBinding: Binding<Int> {
        Binding(
            get: { elapsedSeconds % 60 },
            set: { newValue in
                let seconds = min(max(newValue, 0), 59)
                elapsedSeconds = min(((elapsedSeconds / 60) * 60) + seconds, 7200)
            }
        )
    }

    private func save() {
        let comments = [
            triggers.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : "Triggers: \(triggers.trimmingCharacters(in: .whitespacesAndNewlines))",
            postEventNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : "Post-event notes: \(postEventNotes.trimmingCharacters(in: .whitespacesAndNewlines))"
        ]
        .compactMap { $0 }
        .joined(separator: "\n\n")

        let entry = HealthLogEntry(
            id: UUID(),
            type: .quickLog,
            categoryID: option.id,
            title: option.title,
            timestamp: startTime,
            severity: Int(severity),
            value: "\(durationText(elapsedSeconds)) · \(seizureType)",
            comments: comments
        )
        onSave(entry)
        dismiss()
    }

    private func durationText(_ totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%02d:%02d", minutes, seconds)
    }
}

