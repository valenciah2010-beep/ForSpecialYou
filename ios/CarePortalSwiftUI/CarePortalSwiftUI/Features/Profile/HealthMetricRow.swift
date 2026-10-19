import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct HealthMetricRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 28)

            Text(LocalizedStringKey(title))
                .fontWeight(.semibold)

            Spacer()

            Text(value)
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
    }
}

