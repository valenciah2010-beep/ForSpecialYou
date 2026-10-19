import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct CyclicVomitingTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var lineLimit: ClosedRange<Int> = 1...3

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localizedAppString(title))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.text)

            TextField(localizedAppString(placeholder), text: $text, axis: .vertical)
                .textInputAutocapitalization(.never)
                .lineLimit(lineLimit)
                .padding(12)
                .background(AppTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

