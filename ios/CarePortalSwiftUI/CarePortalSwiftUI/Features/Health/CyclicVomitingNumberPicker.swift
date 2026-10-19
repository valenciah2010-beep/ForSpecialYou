import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct CyclicVomitingNumberPicker: View {
    let title: String
    @Binding var value: Int
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(localizedAppString(title))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.text)
                Spacer()
                Text(localizedAppString("Times per Day"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 14) {
                Button {
                    value = max(0, value - 1)
                } label: {
                    Image(systemName: "minus")
                        .font(.headline.weight(.bold))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.bordered)
                .tint(tint)

                Text("\(value)")
                    .font(.title.weight(.black))
                    .foregroundStyle(AppTheme.text)
                    .frame(minWidth: 62)

                Button {
                    value = min(50, value + 1)
                } label: {
                    Image(systemName: "plus")
                        .font(.headline.weight(.bold))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(tint)

                Spacer()
            }
        }
    }
}

