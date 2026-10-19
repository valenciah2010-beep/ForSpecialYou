import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct QuickLogTrendPreviewCard: View {
    let option: QuickLogOption
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
        if option.id == "seizure" {
            NavigationLink {
                SeizureHistoryDetailView(option: option, entries: entries)
            } label: {
                seizureHistoryCard
            }
            .buttonStyle(.plain)
        } else if option.id == "medsFood" {
            NavigationLink {
                MedicineHistoryDetailView(option: option, entries: entries)
            } label: {
                medicineHistoryCard
            }
            .buttonStyle(.plain)
        } else if option.id == "mood" || option.id == "pain" || option.id == "cyclicVomiting" {
            NavigationLink {
                QuickLogHistoryDetailView(option: option, entries: entries)
            } label: {
                quickLogListCard
            }
            .buttonStyle(.plain)
        } else {
            Button {
            } label: {
                trendChartCard
            }
            .buttonStyle(.plain)
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

                Text(String(format: localizedAppString("%d entries · Avg %@/%d"), entries.count, averageSeverityText, scaleMax))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
        }
    }

    private var trendChartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            cardHeader

            chartPreview
                .frame(height: 110)
                .padding(10)
                .background(AppTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
    }

    private var quickLogListCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            cardHeader

            if recentEntries.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(option.tint)
                        .frame(width: 36, height: 36)
                        .background(option.tint.opacity(0.14))
                        .clipShape(Circle())

                    Text(localizedAppString("No saved logs yet"))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.secondary)

                    Spacer()
                }
                .padding(12)
                .background(AppTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                VStack(spacing: 8) {
                    ForEach(recentEntries.reversed().prefix(3)) { entry in
                        HStack(spacing: 10) {
                            Text(entry.timestamp, format: .dateTime.month(.abbreviated).day())
                                .font(.caption.weight(.black))
                                .foregroundStyle(AppTheme.text)
                                .frame(width: 54, alignment: .leading)

                            Text(entry.value.isEmpty ? entry.title : entry.value)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(AppTheme.text)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text(entry.timestamp, format: .dateTime.hour().minute())
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(AppTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
    }

    private var seizureHistoryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            cardHeader

            HStack(spacing: 10) {
                Image(systemName: "list.bullet.clipboard")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(option.tint)
                    .frame(width: 36, height: 36)
                    .background(option.tint.opacity(0.14))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: localizedAppString("%d saved logs"), entries.count))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppTheme.text)

                    Text(localizedAppString("Dates, times, duration, type, triggers, and notes"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(12)
            .background(AppTheme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
    }

    private var medicineHistoryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            cardHeader

            if recentMedicineDays.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "checklist")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(option.tint)
                        .frame(width: 36, height: 36)
                        .background(option.tint.opacity(0.14))
                        .clipShape(Circle())

                    Text(localizedAppString("No medicine checklist saved yet"))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.secondary)

                    Spacer()
                }
                .padding(12)
                .background(AppTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                VStack(spacing: 8) {
                    ForEach(recentMedicineDays.prefix(3)) { day in
                        HStack(spacing: 10) {
                            Text(day.date, format: .dateTime.month(.abbreviated).day())
                                .font(.caption.weight(.black))
                                .foregroundStyle(AppTheme.text)
                                .frame(width: 54, alignment: .leading)

                            Text(String(format: localizedAppString("Last saved %@"), day.savedTimeText))
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text("\(day.items.count)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                                .frame(width: 28, alignment: .trailing)
                        }
                    }
                }
                .padding(12)
                .background(AppTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
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
            .chartYScale(domain: 0...scaleMax)
            .chartYAxis {
                AxisMarks(values: option.id == "mood" ? [1, 4, 7] : [1, 3, 5])
            }
            .chartXAxis(.hidden)
        }
    }

    private var averageSeverityText: String {
        averageSeverity == 0 ? "0" : String(format: "%.1f", averageSeverity)
    }

    private var scaleMax: Int {
        option.id == "mood" ? 7 : 5
    }

    private var recentMedicineDays: [MedicineHistoryDay] {
        MedicineHistoryDay.days(from: entries)
    }
}

