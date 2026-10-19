import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct ProfileTextField: View {
    let title: String
    @Binding var text: String
    var placeholder: String
    var axis: Axis = .horizontal

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringKey(title))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.text)

            TextField(LocalizedStringKey(placeholder), text: $text, axis: axis)
                .textInputAutocapitalization(.never)
                .padding(12)
                .background(AppTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .lineLimit(axis == .vertical ? 3...5 : 1...1)
        }
    }
}

