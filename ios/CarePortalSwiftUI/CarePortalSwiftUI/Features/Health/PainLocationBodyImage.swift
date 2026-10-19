import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct PainLocationBodyImage: View {
    let side: PainBodySide

    var body: some View {
        if let image = PainLocationBodyImageStore.image(for: side) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .accessibilityHidden(true)
        } else {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 1.00, green: 0.92, blue: 0.94))
                .overlay {
                    Text(localizedAppString("Pain body image missing"))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
        }
    }
}

