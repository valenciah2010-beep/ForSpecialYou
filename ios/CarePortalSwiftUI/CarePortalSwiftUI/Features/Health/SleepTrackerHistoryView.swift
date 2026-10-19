import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct SleepTrackerHistoryView: View {
    let option: SnapshotOption
    let entries: [HealthLogEntry]

    @State private var selectedPeriod: SleepHistoryPeriod = .week
    @State private var selectedSleepRecordID: UUID?

    private var sleepRecords: [SleepTrackerRecord] {
        entries
            .compactMap(SleepTrackerRecord.init(entry:))
            .sorted { $0.date < $1.date }
    }

    private var anchorDate: Date {
        Date()
    }

    private var periodRecords: [SleepTrackerRecord] {
        sleepRecords.filter { selectedPeriod.contains($0.date, relativeTo: anchorDate) }
    }

    private var averageMinutes: Int {
        guard !periodRecords.isEmpty else { return 0 }
        return periodRecords.reduce(0) { $0 + $1.durationMinutes } / periodRecords.count
    }

    private var selectedSleepRecord: SleepTrackerRecord? {
        guard let selectedSleepRecordID else { return nil }
        return periodRecords.first { $0.id == selectedSleepRecordID }
    }

    private var dateRangeText: String {
        selectedPeriod.rangeText(relativeTo: anchorDate)
    }

    private var headerLabel: String {
        guard let selectedSleepRecord else {
            return localizedAppString("AVG. TIME IN BED")
        }

        let wakeText = selectedSleepRecord.wakingCount == 1 ? localizedAppString("1 wake-up") : String(format: localizedAppString("%d wake-ups"), selectedSleepRecord.wakingCount)
        return "\(localizedAppString(selectedSleepRecord.qualityTitle)) · \(wakeText)"
    }

    private var headerValue: String {
        if let selectedSleepRecord {
            return selectedSleepRecord.durationText
        }

        return SleepTrackerRecord.durationText(minutes: averageMinutes)
    }

    private var headerDateText: String {
        if let selectedSleepRecord {
            return localizedDateString(selectedSleepRecord.date, dateStyle: .medium, timeStyle: .none)
        }

        return dateRangeText
    }

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
                .onTapGesture {
                    clearSleepSelection()
                }

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if sleepRecords.isEmpty {
                        Text(localizedAppString("No Sleep & Rest entries yet."))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .authPanel()
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            Picker(localizedAppString("Sleep range"), selection: $selectedPeriod) {
                                ForEach(SleepHistoryPeriod.allCases) { period in
                                    Text(localizedAppString(period.shortTitle)).tag(period)
                                }
                            }
                            .pickerStyle(.segmented)
                            .tint(option.tint)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(option.tint)
                                        .frame(width: 8, height: 8)

                                    Text(headerLabel)
                                        .font(.caption.weight(.black))
                                        .foregroundStyle(.secondary)
                                }

                                Text(headerValue)
                                    .font(.system(size: 34, weight: .black, design: .rounded))
                                    .foregroundStyle(AppTheme.text)

                                Text(headerDateText)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }

                            if periodRecords.isEmpty {
                                Text(localizedAppString("No Sleep & Rest entries for this period."))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .background(AppTheme.fieldBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            } else {
                                SleepVerticalBarChart(
                                    records: periodRecords,
                                    period: selectedPeriod,
                                    anchorDate: anchorDate,
                                    selectedRecordID: selectedSleepRecordID,
                                    tint: option.tint
                                ) { item in
                                    DispatchQueue.main.async {
                                        selectedSleepRecordID = item.recordID
                                    }
                                } onClearSelection: {
                                    clearSleepSelection()
                                }
                                .frame(height: 330)
                            }
                        }
                        .authPanel()
                    }
                }
                .padding(18)
            }
            .simultaneousGesture(
                TapGesture().onEnded {
                    clearSleepSelection()
                }
            )
        }
        .navigationTitle(localizedAppString("Sleep & Rest"))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedPeriod) { _, _ in
            clearSleepSelection()
        }
    }

    private func clearSleepSelection() {
        selectedSleepRecordID = nil
    }
}

