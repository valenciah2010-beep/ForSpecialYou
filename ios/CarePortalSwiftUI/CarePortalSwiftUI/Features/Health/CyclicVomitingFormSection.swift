import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct CyclicVomitingFormSection<Content: View>: View {
    let id: String
    let title: String
    let icon: String
    let tint: Color
    let isCollapsed: Bool
    let onToggle: () -> Void
    let content: Content

    init(
        id: String,
        title: String,
        icon: String,
        tint: Color,
        isCollapsed: Bool,
        onToggle: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.tint = tint
        self.isCollapsed = isCollapsed
        self.onToggle = onToggle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(action: onToggle) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(tint)
                        .frame(width: 30, height: 30)
                        .background(tint.opacity(0.14))
                        .clipShape(Circle())

                    Text(localizedAppString(title))
                        .font(.headline.weight(.black))
                        .foregroundStyle(AppTheme.text)

                    Spacer()

                    Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                }
            }
            .buttonStyle(.plain)

            if !isCollapsed {
                content
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(.white.opacity(0.86))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.accent.opacity(0.10), lineWidth: 1)
        )
    }
}

