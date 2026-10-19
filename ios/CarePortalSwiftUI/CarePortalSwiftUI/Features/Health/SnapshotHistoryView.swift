import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct SnapshotHistoryView: View {
    let options: [SnapshotOption]
    let entries: [HealthLogEntry]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(options) { option in
                    SnapshotHistoryPreviewCard(
                        option: option,
                        entries: entriesFor(option)
                    )
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
    }

    private func entriesFor(_ option: SnapshotOption) -> [HealthLogEntry] {
        entries
            .filter {
                option.id == "mood"
                    ? $0.type == .quickLog && $0.categoryID == "mood"
                    : $0.type == .snapshot && $0.categoryID == option.id
            }
            .sorted { $0.timestamp < $1.timestamp }
    }
}

