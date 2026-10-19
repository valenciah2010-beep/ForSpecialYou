import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct SeizureHistoryDetailView: View {
    let option: QuickLogOption
    let entries: [HealthLogEntry]

    private var sortedEntries: [HealthLogEntry] {
        entries.sorted { $0.timestamp > $1.timestamp }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if sortedEntries.isEmpty {
                    Text(localizedAppString("No seizure logs saved yet."))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .authPanel()
                } else {
                    ForEach(sortedEntries) { entry in
                        SeizureHistoryLogCard(entry: entry, tint: option.tint)
                    }
                }
            }
            .padding(18)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(localizedAppString("Seizure History"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

