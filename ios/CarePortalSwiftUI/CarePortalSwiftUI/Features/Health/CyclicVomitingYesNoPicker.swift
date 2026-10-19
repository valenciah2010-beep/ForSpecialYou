import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct CyclicVomitingYesNoPicker: View {
    let title: String
    @Binding var isYes: Bool?
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(localizedAppString(title))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.text)

            HStack(spacing: 10) {
                yesNoButton(title: "Yes", selected: isYes == true) {
                    isYes = isYes == true ? nil : true
                }
                yesNoButton(title: "No", selected: isYes == false) {
                    isYes = isYes == false ? nil : false
                }
            }
        }
    }

    private func yesNoButton(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(selected ? tint : .secondary.opacity(0.6))

                Text(localizedAppString(title))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.text)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

