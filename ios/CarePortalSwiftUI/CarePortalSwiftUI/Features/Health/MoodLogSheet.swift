import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct MoodLogSheet: View {
    @Environment(\.dismiss) private var dismiss

    let option: QuickLogOption
    let onSave: (HealthLogEntry) -> Void

    @State private var step: MoodLogStep = .kind
    @State private var selectedKind: MoodLogKind?
    @State private var valence = 4
    @State private var selectedWords: Set<String> = []
    @State private var cause = ""

    private var wordGroup: MoodWordGroup {
        MoodWordGroup.group(for: valence)
    }

    private var nextTitle: String {
        step == .cause ? "Done" : "Next"
    }

    private var canContinue: Bool {
        switch step {
        case .kind:
            return selectedKind != nil
        case .valence:
            return true
        case .words:
            return !selectedWords.isEmpty
        case .cause:
            return true
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        switch step {
                        case .kind:
                            kindStep
                        case .valence:
                            valenceStep
                        case .words:
                            wordsStep
                        case .cause:
                            causeStep
                        }
                    }
                    .padding(18)
                }

                Button {
                    advance()
                } label: {
                    Text(nextTitle)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(canContinue ? option.tint : Color.secondary.opacity(0.45))
                        .clipShape(Capsule())
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                }
                .disabled(!canContinue)
                .buttonStyle(.plain)
                .background(AppTheme.background)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if step != .kind {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(localizedAppString("Back")) {
                            goBack()
                        }
                        .foregroundStyle(AppTheme.accent)
                    }
                }

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

    private var kindStep: some View {
        VStack(spacing: 12) {
            ForEach(MoodLogKind.allCases) { kind in
                Button {
                    selectedKind = kind
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(LocalizedStringKey(kind.rawValue))
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.text)

                            Text(kind == .currentEmotion ? currentTimeText : localizedAppString("For the whole day"))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: selectedKind == kind ? "checkmark.circle.fill" : "circle")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(selectedKind == kind ? option.tint : .secondary)
                    }
                    .padding(16)
                    .background(selectedKind == kind ? option.tint.opacity(0.18) : AppTheme.panel)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(selectedKind == kind ? option.tint.opacity(0.5) : Color.clear, lineWidth: 2)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var valenceStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizedStringKey(MoodValence.title(for: valence)))
                .font(.title2.weight(.black))
                .foregroundStyle(AppTheme.text)

            MoodValenceSlider(value: $valence, tint: option.tint)
        }
        .authPanel()
    }

    private var wordsStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(LocalizedStringKey(wordGroup.title))
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.text)

            FlowLayout(spacing: 9, rowSpacing: 9) {
                ForEach(wordGroup.words, id: \.self) { word in
                    Button {
                        toggleWord(word)
                    } label: {
                        Text(LocalizedStringKey(word))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(selectedWords.contains(word) ? .white : AppTheme.text)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(selectedWords.contains(word) ? option.tint : AppTheme.fieldBackground)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .authPanel()
    }

    private var causeStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localizedAppString("What may have caused this feeling?"))
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.text)

            TextField(localizedAppString("Add context, trigger, activity, place, person, or change in routine"), text: $cause, axis: .vertical)
                .textInputAutocapitalization(.never)
                .lineLimit(6...9)
                .padding(12)
                .background(AppTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .authPanel()
    }

    private var currentTimeText: String {
        localizedDateString(Date(), dateStyle: .none, timeStyle: .short)
    }

    private func toggleWord(_ word: String) {
        if selectedWords.contains(word) {
            selectedWords.remove(word)
        } else {
            selectedWords.insert(word)
        }
    }

    private func advance() {
        switch step {
        case .kind:
            step = .valence
        case .valence:
            selectedWords.removeAll()
            step = .words
        case .words:
            step = .cause
        case .cause:
            save()
        }
    }

    private func goBack() {
        switch step {
        case .kind:
            dismiss()
        case .valence:
            step = .kind
        case .words:
            step = .valence
        case .cause:
            step = .words
        }
    }

    private func save() {
        let sortedWords = wordGroup.words.filter { selectedWords.contains($0) }
        let kindTitle = selectedKind?.rawValue ?? "Mood"
        let valenceTitle = MoodValence.title(for: valence)
        let wordText = sortedWords.joined(separator: ", ")
        let value = "\(kindTitle): \(valenceTitle)"
        let detailLines = [
            wordText.isEmpty ? nil : "States: \(wordText)",
            cause.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : "Cause: \(cause.trimmingCharacters(in: .whitespacesAndNewlines))"
        ].compactMap { $0 }

        let entry = HealthLogEntry(
            id: UUID(),
            type: .quickLog,
            categoryID: option.id,
            title: option.title,
            timestamp: Date(),
            severity: valence,
            value: value,
            comments: detailLines.joined(separator: "\n")
        )
        onSave(entry)
        dismiss()
    }
}

