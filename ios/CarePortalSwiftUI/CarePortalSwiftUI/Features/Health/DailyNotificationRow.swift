import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct DailyNotificationRow: View {
    let notification: DailyNotificationItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(notification.title.isEmpty ? localizedAppString("Notification") : localizedAppString(notification.title))
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.text)

                Spacer()

                Text(localizedDateString(notification.date, dateStyle: .none, timeStyle: .short))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }

            if !notification.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(localizedAppString(notification.body))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(AppTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

