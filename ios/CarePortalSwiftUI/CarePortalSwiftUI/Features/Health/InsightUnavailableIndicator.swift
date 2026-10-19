import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct InsightUnavailableIndicator: View {
    var body: some View {
        HStack {
            Spacer()

            Image(systemName: "sparkles.slash")
                .font(.headline.weight(.bold))
                .foregroundStyle(.secondary)
                .frame(width: 38, height: 38)
                .background(AppTheme.panel)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                .accessibilityLabel(localizedAppString("AI insights unavailable"))

            Spacer()
        }
    }
}

