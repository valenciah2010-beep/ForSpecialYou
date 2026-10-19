import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct HealthDashboardHeader: View {
    let childName: String
    let parentName: String
    let imageData: Data
    let onProfileTap: () -> Void
    let onNotificationTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onProfileTap) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.75))
                        .frame(width: 52, height: 52)

                    if let image = profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 48, height: 48)
                            .clipShape(Circle())
                    } else {
                        Text(initials)
                            .font(.headline.weight(.black))
                            .foregroundStyle(AppTheme.accent)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(localizedAppString("Open profile"))

            VStack(alignment: .leading, spacing: 3) {
                Text(String(format: localizedAppString("%@'s Day"), childName))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.text)
                    .lineLimit(1)

                Text(String(format: localizedAppString("Monitored by %@"), parentName))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onNotificationTap) {
                Image(systemName: "bell.badge")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppTheme.text)
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(localizedAppString("Open notifications"))
        }
        .padding(14)
        .background(Color(red: 0.82, green: 0.94, blue: 0.94))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var initials: String {
        childName
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map { String($0).uppercased() }
            .joined()
    }

    private var profileImage: UIImage? {
        guard !imageData.isEmpty else { return nil }
        return UIImage(data: imageData)
    }
}

