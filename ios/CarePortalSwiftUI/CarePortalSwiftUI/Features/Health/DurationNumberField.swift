import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct DurationNumberField: View {
    let title: String
    @Binding var value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(localizedAppString(title))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField("0", value: $value, format: .number)
                .keyboardType(.numberPad)
                .font(.title3.weight(.bold))
                .monospacedDigit()
                .multilineTextAlignment(.center)
                .padding(.vertical, 12)
                .padding(.horizontal, 10)
                .background(AppTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .frame(maxWidth: .infinity)
    }
}

