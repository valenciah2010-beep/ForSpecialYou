import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct CyclicVomitingSingleChoiceSection: View {
    let title: String
    let options: [String]
    @Binding var selection: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(localizedAppString(title))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.text)

            FlowLayout(spacing: 8, rowSpacing: 8) {
                ForEach(options, id: \.self) { option in
                    CyclicVomitingOptionChip(
                        title: option,
                        isSelected: selection == option,
                        tint: tint
                    ) {
                        selection = selection == option ? "" : option
                    }
                }
            }
        }
    }
}

