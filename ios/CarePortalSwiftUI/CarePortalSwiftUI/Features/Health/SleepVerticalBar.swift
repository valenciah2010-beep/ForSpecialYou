import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct SleepVerticalBar: View {
    let item: SleepChartItem
    let isSelected: Bool
    let tint: Color
    let domainStart: Int
    let domainEnd: Int
    let chartHeight: CGFloat
    let onSelect: (SleepChartItem) -> Void

    private var topY: CGFloat {
        yPosition(for: item.startMinutes)
    }

    private var bottomY: CGFloat {
        yPosition(for: item.endMinutes)
    }

    private var barHeight: CGFloat {
        max(8, bottomY - topY)
    }

    var body: some View {
        Button {
            guard item.durationMinutes > 0 else { return }
            onSelect(item)
        } label: {
            ZStack(alignment: .top) {
                if item.durationMinutes > 0 {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(tint.opacity(isSelected ? 1 : 0.90))
                        .frame(maxWidth: .infinity)
                        .frame(height: barHeight)
                        .overlay {
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .stroke(isSelected ? AppTheme.text.opacity(0.25) : Color.clear, lineWidth: 2)
                        }
                        .offset(y: topY)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: chartHeight, alignment: .top)
        }
        .buttonStyle(.plain)
        .disabled(item.durationMinutes == 0)
    }

    private func yPosition(for minutes: Int) -> CGFloat {
        let clamped = min(max(minutes, domainStart), domainEnd)
        let percentage = CGFloat(clamped - domainStart) / CGFloat(max(1, domainEnd - domainStart))
        return chartHeight * percentage
    }
}

