import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct SnapshotHistoryPreviewCard: View {
    let option: SnapshotOption
    let entries: [HealthLogEntry]

    private var recentEntries: [HealthLogEntry] {
        Array(entries.suffix(8))
    }

    private var averageSeverity: Double {
        guard !entries.isEmpty else { return 0 }
        let total = entries.reduce(0) { $0 + $1.severity }
        return Double(total) / Double(entries.count)
    }

    var body: some View {
        if option.id == "sleep" {
            NavigationLink {
                SleepTrackerHistoryView(option: option, entries: entries)
            } label: {
                sleepTrackerCard
            }
            .buttonStyle(.plain)
        } else {
            VStack(alignment: .leading, spacing: 14) {
                cardHeader

                chartPreview
                    .frame(height: 110)
                    .padding(10)
                    .background(AppTheme.fieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .snapshotHistoryCardStyle()
        }
    }

    private var cardHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: option.icon)
                .font(.title2.weight(.bold))
                .foregroundStyle(option.tint)
                .frame(width: 48, height: 48)
                .background(option.tint.opacity(0.16))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(LocalizedStringKey(option.title))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.text)

                Text(String(format: localizedAppString("%d entries · Avg %@/5"), entries.count, averageSeverityText))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
        }
    }

    private var sleepTrackerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            cardHeader

            HStack(spacing: 10) {
                Image(systemName: "bed.double.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(option.tint)
                    .frame(width: 36, height: 36)
                    .background(option.tint.opacity(0.14))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: localizedAppString("%d nights tracked"), entries.count))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppTheme.text)

                    Text(localizedAppString("Sleep times and nightly duration"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(12)
            .background(AppTheme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .snapshotHistoryCardStyle()
    }

    @ViewBuilder
    private var chartPreview: some View {
        if recentEntries.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "chart.bar")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(option.tint)

                Text(localizedAppString("No data yet"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Chart(recentEntries) { entry in
                LineMark(
                    x: .value("Time", entry.timestamp),
                    y: .value("Severity", entry.severity)
                )
                .foregroundStyle(option.tint)
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Time", entry.timestamp),
                    y: .value("Severity", entry.severity)
                )
                .foregroundStyle(option.tint)
            }
            .chartYScale(domain: 0...5)
            .chartYAxis {
                AxisMarks(values: [1, 3, 5])
            }
            .chartXAxis(.hidden)
        }
    }

    private var averageSeverityText: String {
        averageSeverity == 0 ? "0" : String(format: "%.1f", averageSeverity)
    }
}

