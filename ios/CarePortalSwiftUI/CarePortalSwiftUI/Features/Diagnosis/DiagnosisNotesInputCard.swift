import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct DiagnosisNotesInputCard: View {
    @Binding var notes: String
    let placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localizedAppString("Notes"))
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.text)

            TextField(localizedAppString(placeholder), text: $notes, axis: .vertical)
                .textInputAutocapitalization(.sentences)
                .lineLimit(6...12)
                .padding(14)
                .background(AppTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .diagnosisDetailCard()
    }
}

