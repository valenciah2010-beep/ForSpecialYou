import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct ModalToolbarTitle: View {
    let icon: String?
    let title: String
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            if let icon, !icon.isEmpty {
                Image(systemName: icon)
                    .font(.caption.weight(.black))
                    .foregroundStyle(tint)
            }

            Text(localizedAppString(title))
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .accessibilityElement(children: .combine)
    }
}

