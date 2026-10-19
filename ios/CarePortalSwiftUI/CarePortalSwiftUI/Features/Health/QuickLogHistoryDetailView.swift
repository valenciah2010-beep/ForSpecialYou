import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct QuickLogHistoryDetailView: View {
    let option: QuickLogOption
    let entries: [HealthLogEntry]

    private var sortedEntries: [HealthLogEntry] {
        entries.sorted { $0.timestamp > $1.timestamp }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if sortedEntries.isEmpty {
                    Text(localizedAppString("No saved logs yet"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .authPanel()
                } else {
                    ForEach(sortedEntries) { entry in
                        QuickLogHistoryLogCard(entry: entry, option: option)
                    }
                }
            }
            .padding(18)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(String(format: localizedAppString("%@ History"), localizedAppString(option.title)))
        .navigationBarTitleDisplayMode(.inline)
    }
}

