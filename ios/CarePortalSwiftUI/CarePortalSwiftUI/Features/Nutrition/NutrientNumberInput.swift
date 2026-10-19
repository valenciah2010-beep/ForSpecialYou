import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct NutrientNumberInput: View {
    let title: String
    let unit: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Text(LocalizedStringKey(title))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.text)

            Spacer()

            TextField("0", text: numericText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .font(.headline.weight(.bold))
                .frame(width: 90)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(AppTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text(unit)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .leading)
        }
    }

    private var numericText: Binding<String> {
        Binding(
            get: { text },
            set: { text = $0.filter(\.isNumber) }
        )
    }
}

