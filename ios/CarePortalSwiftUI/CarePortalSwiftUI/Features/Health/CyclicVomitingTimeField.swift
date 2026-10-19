import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct CyclicVomitingTimeField: View {
    let title: String
    @Binding var selection: Date
    let tint: Color
    @State private var isDatePickerPresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localizedAppString(title))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.text)

            HStack(spacing: 10) {
                Button {
                    isDatePickerPresented = true
                } label: {
                    Image(systemName: "calendar")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(tint)
                        .frame(width: 28, height: 28)
                        .background(tint.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                }
                .buttonStyle(.plain)
                .popover(isPresented: $isDatePickerPresented) {
                    VStack(spacing: 12) {
                        DatePicker(
                            "",
                            selection: $selection,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.graphical)
                        .labelsHidden()

                        Button(localizedAppString("Done")) {
                            isDatePickerPresented = false
                        }
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(tint)
                    }
                    .padding()
                    .frame(minWidth: 320)
                    .presentationCompactAdaptation(.popover)
                }

                DatePicker(
                    "",
                    selection: $selection,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .labelsHidden()
                .datePickerStyle(.compact)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(AppTheme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(tint.opacity(0.18), lineWidth: 1)
            )
        }
    }
}

