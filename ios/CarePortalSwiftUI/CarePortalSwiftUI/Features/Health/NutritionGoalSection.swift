import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct NutritionGoalSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(localizedAppString(title))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.text)

            VStack(spacing: 10) {
                content
            }
        }
    }
}

