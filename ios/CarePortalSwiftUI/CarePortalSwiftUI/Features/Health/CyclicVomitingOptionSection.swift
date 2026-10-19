import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct CyclicVomitingOptionSection: View {
    let title: String
    var titleNote = ""
    let options: [String]
    @Binding var selection: Set<String>
    let tint: Color
    let otherPlaceholder: String
    @Binding var otherText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !title.isEmpty {
                HStack(spacing: 6) {
                    Text(localizedAppString(title))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.text)

                    if !titleNote.isEmpty {
                        Text(localizedAppString(titleNote))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(tint)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(tint.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }

            FlowLayout(spacing: 8, rowSpacing: 8) {
                ForEach(options, id: \.self) { option in
                    CyclicVomitingOptionChip(
                        title: option,
                        isSelected: selection.contains(option),
                        tint: tint
                    ) {
                        toggle(option)
                    }
                }
            }

            if !otherPlaceholder.isEmpty {
                TextField(localizedAppString(otherPlaceholder), text: $otherText, axis: .vertical)
                    .textInputAutocapitalization(.never)
                    .lineLimit(1...3)
                    .padding(12)
                    .background(AppTheme.fieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private func toggle(_ option: String) {
        if selection.contains(option) {
            selection.remove(option)
            return
        }

        if option.hasPrefix("None") {
            selection = [option]
        } else {
            selection = selection.filter { !$0.hasPrefix("None") }
            selection.insert(option)
        }
    }
}

