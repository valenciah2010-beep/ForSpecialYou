import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct CyclicVomitingCompactTextField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(localizedAppString(placeholder), text: digitsOnlyText)
            .keyboardType(.numberPad)
            .padding(12)
            .background(AppTheme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var digitsOnlyText: Binding<String> {
        Binding(
            get: { text },
            set: { newValue in
                text = newValue.filter(\.isNumber)
            }
        )
    }
}

