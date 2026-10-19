import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct HealthTrendChart: View {
    let entries: [HealthLogEntry]

    private var recentEntries: [HealthLogEntry] {
        Array(entries.sorted { $0.timestamp < $1.timestamp }.suffix(12))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if recentEntries.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(localizedAppString("No trend data yet"))
                        .font(.headline.weight(.bold))

                    Text(localizedAppString("Tap a quick-log or daily snapshot card to save the first entry."))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(AppTheme.panel)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                Chart(recentEntries) { entry in
                    BarMark(
                        x: .value("Entry", entry.timestamp, unit: .minute),
                        y: .value("Severity", entry.severity)
                    )
                    .foregroundStyle(by: .value("Type", entry.title))
                }
                .chartYScale(domain: 0...5)
                .chartYAxis {
                    AxisMarks(values: [1, 2, 3, 4, 5])
                }
                .frame(height: 180)
                .padding(14)
                .background(AppTheme.panel)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(spacing: 8) {
                    ForEach(recentEntries.suffix(3).reversed()) { entry in
                        TrendEntryRow(entry: entry)
                    }
                }
            }
        }
    }
}

