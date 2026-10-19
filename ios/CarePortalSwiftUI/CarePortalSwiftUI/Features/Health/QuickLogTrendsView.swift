import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct QuickLogTrendsView: View {
    let options: [QuickLogOption]
    let entries: [HealthLogEntry]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if options.isEmpty {
                    Text(localizedAppString("Choose quick-log buttons on the dashboard to see history here."))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .authPanel()
                } else {
                    LazyVStack(spacing: 14) {
                        ForEach(options) { option in
                            QuickLogTrendPreviewCard(
                                option: option,
                                entries: entriesFor(option)
                            )
                        }
                    }
                }
            }
            .padding(18)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            OrientationController.shared.lock(to: .portrait)
        }
        .onDisappear {
            OrientationController.shared.unlock()
        }
    }

    private func entriesFor(_ option: QuickLogOption) -> [HealthLogEntry] {
        entries
            .filter { $0.type == .quickLog && $0.categoryID == option.id }
            .sorted { $0.timestamp < $1.timestamp }
    }
}

