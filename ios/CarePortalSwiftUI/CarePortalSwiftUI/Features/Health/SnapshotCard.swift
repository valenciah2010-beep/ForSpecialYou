import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct SnapshotCard: View {
    let option: SnapshotOption
    var displayValue: String?
    var displayDetail: String?
    var displayIcon: String?
    var sleepDurationText: String?
    var isLoggedToday = true
    let action: () -> Void

    private var valueText: String {
        isLoggedToday ? (displayValue ?? localizedAppString(option.value)) : "--"
    }

    private var detailText: String {
        isLoggedToday ? (displayDetail ?? localizedAppString(option.detail)) : localizedAppString(option.emptyCaption)
    }

    private var iconName: String {
        displayIcon ?? option.icon
    }

    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: 10) {
                Image(systemName: iconName)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(option.tint)
                    .frame(height: 40)

                Text(LocalizedStringKey(option.dashboardLabel))
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.text)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.78)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 118)
            .background(option.tint.opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(option.tint.opacity(0.24), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

