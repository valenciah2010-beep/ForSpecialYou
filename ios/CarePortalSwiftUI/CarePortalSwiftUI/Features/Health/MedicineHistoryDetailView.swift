import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct MedicineHistoryDetailView: View {
    let option: QuickLogOption
    let entries: [HealthLogEntry]

    private var days: [MedicineHistoryDay] {
        MedicineHistoryDay.days(from: entries)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if days.isEmpty {
                    Text(localizedAppString("No medicine checklist saved yet."))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .authPanel()
                } else {
                    ForEach(days) { day in
                        MedicineHistoryDayCard(day: day, tint: option.tint)
                    }
                }
            }
            .padding(18)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(localizedAppString("Medicine History"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

