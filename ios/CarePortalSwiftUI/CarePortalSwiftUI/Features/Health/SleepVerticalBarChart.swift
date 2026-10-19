import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct SleepVerticalBarChart: View {
    let records: [SleepTrackerRecord]
    let period: SleepHistoryPeriod
    let anchorDate: Date
    let selectedRecordID: UUID?
    let tint: Color
    let onSelect: (SleepChartItem) -> Void
    let onClearSelection: () -> Void

    private let axisWidth: CGFloat = 48
    private let labelHeight: CGFloat = 28

    private var chartItems: [SleepChartItem] {
        SleepChartItem.items(from: records, period: period, anchorDate: anchorDate)
    }

    private var domainStart: Int {
        let earliest = chartItems.map(\.startMinutes).min() ?? (22 * 60)
        return min(22 * 60, (earliest / 60) * 60)
    }

    private var domainEnd: Int {
        let latest = chartItems.map(\.endMinutes).max() ?? (32 * 60)
        return max(32 * 60, ((latest + 59) / 60) * 60)
    }

    private var axisMarks: [Int] {
        Array(stride(from: domainStart, through: domainEnd, by: 120))
    }

    var body: some View {
        GeometryReader { proxy in
            let chartWidth = max(1, proxy.size.width - axisWidth)
            let chartHeight = max(1, proxy.size.height - labelHeight)

            HStack(alignment: .top, spacing: 8) {
                ZStack(alignment: .topLeading) {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onClearSelection()
                        }

                    ForEach(axisMarks, id: \.self) { minute in
                        let y = yPosition(for: minute, height: chartHeight)

                        Rectangle()
                            .fill(Color.secondary.opacity(0.10))
                            .frame(width: chartWidth, height: 1)
                            .offset(y: y)
                    }

                    HStack(alignment: .top, spacing: barSpacing(for: chartItems.count)) {
                        ForEach(chartItems) { item in
                            SleepVerticalBar(
                                item: item,
                                isSelected: item.recordID == selectedRecordID,
                                tint: tint,
                                domainStart: domainStart,
                                domainEnd: domainEnd,
                                chartHeight: chartHeight,
                                onSelect: onSelect
                            )
                        }
                    }
                    .frame(width: chartWidth, height: chartHeight, alignment: .top)
                }
                .frame(width: chartWidth, height: chartHeight, alignment: .topLeading)

                ZStack(alignment: .topLeading) {
                    ForEach(axisMarks, id: \.self) { minute in
                        Text(Self.hourLabel(minute))
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                            .offset(y: yPosition(for: minute, height: chartHeight) - 7)
                    }
                }
                .frame(width: axisWidth, height: chartHeight, alignment: .topLeading)
            }
            .overlay(alignment: .bottomLeading) {
                HStack(alignment: .top, spacing: barSpacing(for: chartItems.count)) {
                    ForEach(chartItems) { item in
                        Text(item.label)
                            .font(.caption2.weight(.black))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.55)
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(width: chartWidth)
                .offset(y: labelHeight - 2)
            }
        }
        .padding(12)
        .background(AppTheme.fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func yPosition(for minutes: Int, height: CGFloat) -> CGFloat {
        let clamped = min(max(minutes, domainStart), domainEnd)
        let percentage = CGFloat(clamped - domainStart) / CGFloat(max(1, domainEnd - domainStart))
        return height * percentage
    }

    private func barSpacing(for count: Int) -> CGFloat {
        count > 16 ? 4 : 10
    }

    static func hourLabel(_ minutes: Int) -> String {
        let hour = ((minutes / 60) % 24 + 24) % 24
        let languageCode = UserDefaults.standard.string(forKey: AppLanguage.storageKey) ?? AppLanguage.english.rawValue
        if AppLanguage(code: languageCode) == .chinese {
            return String(format: "%02d:00", hour)
        }

        switch hour {
        case 0:
            return "12 AM"
        case 1...11:
            return "\(hour) AM"
        case 12:
            return "12 PM"
        default:
            return "\(hour - 12) PM"
        }
    }
}

