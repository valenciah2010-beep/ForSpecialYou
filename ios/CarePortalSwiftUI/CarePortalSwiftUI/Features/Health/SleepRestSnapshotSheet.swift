import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct SleepRestSnapshotSheet: View {
    @Environment(\.dismiss) private var dismiss

    let target: SleepSnapshotEditorTarget
    let onSave: (HealthLogEntry) -> Void

    @State private var fellAsleepAt: Date
    @State private var wokeUpAt: Date
    @State private var selectedQuality: SleepRestQuality
    @State private var wakingCount: Int
    @State private var comments: String

    private var option: SnapshotOption {
        target.option
    }

    init(target: SleepSnapshotEditorTarget, onSave: @escaping (HealthLogEntry) -> Void) {
        self.target = target
        self.onSave = onSave

        let prefill = Self.prefill(from: target.existingEntry)
        self._fellAsleepAt = State(initialValue: prefill.fellAsleepAt)
        self._wokeUpAt = State(initialValue: prefill.wokeUpAt)
        self._selectedQuality = State(initialValue: prefill.quality)
        self._wakingCount = State(initialValue: prefill.wakingCount)
        self._comments = State(initialValue: prefill.comments)
    }

    private var sleepDuration: TimeInterval {
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: fellAsleepAt)
        let endComponents = calendar.dateComponents([.hour, .minute], from: wokeUpAt)
        let today = calendar.startOfDay(for: Date())
        let start = calendar.date(
            bySettingHour: startComponents.hour ?? 21,
            minute: startComponents.minute ?? 0,
            second: 0,
            of: today
        ) ?? today
        var end = calendar.date(
            bySettingHour: endComponents.hour ?? 7,
            minute: endComponents.minute ?? 0,
            second: 0,
            of: today
        ) ?? today

        if end <= start {
            end = calendar.date(byAdding: .day, value: 1, to: end) ?? end
        }

        return end.timeIntervalSince(start)
    }

    private var durationText: String {
        let totalMinutes = max(0, Int(sleepDuration / 60))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return minutes == 0 ? "\(hours)h" : "\(hours)h \(minutes)m"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(spacing: 12) {
                            Text(durationText)
                                .font(.title.weight(.black))
                                .foregroundStyle(AppTheme.text)
                                .frame(width: 82, height: 58)
                                .background(option.tint.opacity(0.18))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                            VStack(alignment: .leading, spacing: 3) {
                                Text(localizedAppString("Sleep & Rest"))
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(AppTheme.text)

                                Text(String(format: localizedAppString("%@ tracked"), durationText))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }

                        VStack(alignment: .leading, spacing: 16) {
                            Text(localizedAppString("Sleep Times"))
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.text)

                            TimeWheelPicker(title: localizedAppString("Fell asleep at"), selection: $fellAsleepAt)
                            TimeWheelPicker(title: localizedAppString("Woke up at"), selection: $wokeUpAt)
                        }
                        .authPanel()

                        VStack(alignment: .leading, spacing: 12) {
                            Text(localizedAppString("Rest Quality"))
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.text)

                            HStack(spacing: 10) {
                                ForEach(SleepRestQuality.allCases) { quality in
                                    Button {
                                        selectedQuality = quality
                                    } label: {
                                        VStack(spacing: 6) {
                                            Text(quality.emoji)
                                                .font(.title2)
                                            Text(LocalizedStringKey(quality.title))
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(AppTheme.text)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.75)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(selectedQuality == quality ? option.tint.opacity(0.25) : AppTheme.fieldBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(selectedQuality == quality ? option.tint : Color.clear, lineWidth: 2)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .authPanel()

                        VStack(alignment: .leading, spacing: 12) {
                            Text(localizedAppString("Waking Counter"))
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.text)

                            HStack(spacing: 14) {
                                Button {
                                    wakingCount = max(0, wakingCount - 1)
                                } label: {
                                    Image(systemName: "minus")
                                        .font(.headline.weight(.bold))
                                        .frame(width: 44, height: 44)
                                }
                                .buttonStyle(.bordered)
                                .tint(option.tint)

                                Text("\(wakingCount)")
                                    .font(.title.weight(.black))
                                    .foregroundStyle(AppTheme.text)
                                    .frame(minWidth: 54)

                                Button {
                                    wakingCount += 1
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.headline.weight(.bold))
                                        .frame(width: 44, height: 44)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(option.tint)

                                Text(localizedAppString(wakingCount == 1 ? "wake-up" : "wake-ups"))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)

                                Spacer()
                            }
                        }
                        .authPanel()

                        VStack(alignment: .leading, spacing: 8) {
                            Text(localizedAppString("Notes"))
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.text)

                            TextField(localizedAppString("Nap, bedtime routine, night waking, comfort item, etc."), text: $comments, axis: .vertical)
                                .textInputAutocapitalization(.never)
                                .lineLimit(3...6)
                                .padding(12)
                                .background(AppTheme.fieldBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
        let value = "\(durationText) · \(selectedQuality.title) · \(wakingCount) \(wakingCount == 1 ? "wake-up" : "wake-ups")"
        let timeSummary = "Fell asleep at \(formattedTime(fellAsleepAt))\nWoke up at \(formattedTime(wokeUpAt))"
        let trimmedComments = comments.trimmingCharacters(in: .whitespacesAndNewlines)
        let noteText = trimmedComments.isEmpty ? timeSummary : "\(timeSummary)\n\(trimmedComments)"

        let entry = HealthLogEntry(
            id: target.existingEntry?.id ?? UUID(),
            type: .snapshot,
            categoryID: option.id,
            title: option.title,
            timestamp: target.existingEntry?.timestamp ?? Date(),
            severity: selectedQuality.severity,
            value: value,
            comments: noteText
        )
        onSave(entry)
        dismiss()
    }

    private func formattedTime(_ date: Date) -> String {
        localizedDateString(date, dateStyle: .none, timeStyle: .short)
    }

    private static func prefill(from entry: HealthLogEntry?) -> SleepSnapshotPrefill {
        let defaultSleep = defaultTime(hour: 21, minute: 0)
        let defaultWake = defaultTime(hour: 7, minute: 0)

        guard let entry else {
            return SleepSnapshotPrefill(
                fellAsleepAt: defaultSleep,
                wokeUpAt: defaultWake,
                quality: .normal,
                wakingCount: 0,
                comments: ""
            )
        }

        let valueParts = entry.value
            .components(separatedBy: "·")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        let quality = valueParts
            .compactMap { SleepRestQuality(title: $0) }
            .first ?? .normal

        let wakingCount = valueParts
            .compactMap { part -> Int? in
                guard part.localizedCaseInsensitiveContains("wake") else { return nil }
                return Int(part.filter(\.isNumber))
            }
            .first ?? 0

        let lines = entry.comments
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        let fellAsleepAt = lines
            .first { $0.localizedCaseInsensitiveContains("fell asleep at") }
            .flatMap { timeFromLine($0, prefix: "Fell asleep at") } ?? defaultSleep

        let wokeUpAt = lines
            .first { $0.localizedCaseInsensitiveContains("woke up at") }
            .flatMap { timeFromLine($0, prefix: "Woke up at") } ?? defaultWake

        let comments = lines
            .filter {
                !$0.localizedCaseInsensitiveContains("fell asleep at")
                    && !$0.localizedCaseInsensitiveContains("woke up at")
            }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return SleepSnapshotPrefill(
            fellAsleepAt: fellAsleepAt,
            wokeUpAt: wokeUpAt,
            quality: quality,
            wakingCount: wakingCount,
            comments: comments
        )
    }

    private static func defaultTime(hour: Int, minute: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }

    private static func timeFromLine(_ line: String, prefix: String) -> Date? {
        let rawTime = line
            .replacingOccurrences(of: prefix, with: "", options: [.caseInsensitive])
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\u{202F}", with: " ")
            .replacingOccurrences(of: "\u{00A0}", with: " ")

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"

        guard let parsed = formatter.date(from: rawTime) else { return nil }

        let components = Calendar.current.dateComponents([.hour, .minute], from: parsed)
        return Calendar.current.date(
            bySettingHour: components.hour ?? 0,
            minute: components.minute ?? 0,
            second: 0,
            of: Date()
        )
    }
}

