import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct DigestionSnapshotSheet: View {
    @Environment(\.dismiss) private var dismiss

    let option: SnapshotOption
    let onSave: (HealthLogEntry) -> Void

    @State private var movementTime = Date()
    @State private var selectedStoolType = 4
    @State private var selectedVolume = "Medium"
    @State private var selectedColor = DigestionStoolColor.brown
    @State private var hasStraining: Bool?
    @State private var hasGas: Bool?
    @State private var hasUndigestedFood: Bool?
    @State private var isInfoPresented = false

    private let volumeOptions = ["Small", "Medium", "Large"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 12) {
                        Text(localizedAppString("Movement time"))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.text)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        Spacer(minLength: 8)

                        DatePicker(
                            "",
                            selection: $movementTime,
                            displayedComponents: [.hourAndMinute]
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                    }
                    .authPanel()

                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(localizedAppString("Consistency"))
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(AppTheme.text)

                                Text(localizedAppString("The Bristol Stool Chart"))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button {
                                isInfoPresented = true
                            } label: {
                                Image(systemName: "info.circle.fill")
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(option.tint)
                                    .frame(width: 34, height: 34)
                                    .background(option.tint.opacity(0.14))
                                    .clipShape(Circle())
                            }
                            .accessibilityLabel(localizedAppString("Show stool type descriptions"))
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(1...7, id: \.self) { type in
                                    StoolTypePickerCard(
                                        type: type,
                                        isSelected: selectedStoolType == type,
                                        tint: option.tint
                                    ) {
                                        selectedStoolType = type
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .authPanel()

                    VStack(alignment: .leading, spacing: 12) {
                        Text(localizedAppString("Volume"))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.text)

                        HStack(spacing: 10) {
                            ForEach(volumeOptions, id: \.self) { volume in
                                Button {
                                    selectedVolume = volume
                                } label: {
                                    Text(localizedAppString(volume))
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(selectedVolume == volume ? .white : AppTheme.text)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(selectedVolume == volume ? option.tint : AppTheme.fieldBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .authPanel()

                    VStack(alignment: .leading, spacing: 12) {
                        Text(localizedAppString("Color Check"))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.text)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                            ForEach(DigestionStoolColor.allCases) { stoolColor in
                                Button {
                                    selectedColor = stoolColor
                                } label: {
                                    VStack(spacing: 7) {
                                        Circle()
                                            .fill(stoolColor.swatch)
                                            .frame(width: 30, height: 30)
                                            .overlay {
                                                Circle()
                                                    .stroke(
                                                        selectedColor == stoolColor ? option.tint : Color.black.opacity(0.12),
                                                        lineWidth: selectedColor == stoolColor ? 3 : 1
                                                    )
                                            }

                                        Text(localizedAppString(stoolColor.title))
                                            .font(.caption2.weight(.bold))
                                            .foregroundStyle(AppTheme.text)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.75)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(selectedColor == stoolColor ? option.tint.opacity(0.14) : AppTheme.fieldBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .authPanel()

                    VStack(alignment: .leading, spacing: 12) {
                        Text(localizedAppString("Pain & Strain"))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.text)

                        DigestionYesNoRow(
                            title: "Straining/Discomfort during the movement?",
                            value: $hasStraining,
                            tint: option.tint
                        )

                        DigestionYesNoRow(
                            title: "Excessive gas or bloating noticed afterward?",
                            value: $hasGas,
                            tint: option.tint
                        )

                        DigestionYesNoRow(
                            title: "Visible undigested food in the stool?",
                            value: $hasUndigestedFood,
                            tint: option.tint
                        )
                    }
                    .authPanel()
                    }
                    .padding(18)
                }
                StickyBottomSaveButton(title: "Save Log", tint: AppTheme.accent) {
                    save()
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ToolbarCloseButton {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .principal) {
                    ModalToolbarTitle(icon: option.icon, title: option.title, tint: option.tint)
                }

            }
        }
        .presentationDetents([.large])
        .sheet(isPresented: $isInfoPresented) {
            BristolStoolInfoSheet(tint: option.tint)
        }
    }

    private func save() {
        let group = BristolStoolGuide.group(for: selectedStoolType)
        let description = BristolStoolGuide.description(for: selectedStoolType)
        let value = "\(localizedAppString("Type")) \(selectedStoolType) · \(localizedAppString(group))"
        let detailLines = [
            "\(localizedAppString("Time")): \(localizedDateString(movementTime, dateStyle: .none, timeStyle: .short))",
            "\(localizedAppString("Consistency")): \(localizedAppString("Type")) \(selectedStoolType) - \(localizedAppString(description))",
            "\(localizedAppString("Volume")): \(localizedAppString(selectedVolume))",
            "\(localizedAppString("Color")): \(localizedAppString(selectedColor.title))",
            "\(localizedAppString("Straining/Discomfort")): \(answerText(hasStraining))",
            "\(localizedAppString("Gas/Bloating")): \(answerText(hasGas))",
            "\(localizedAppString("Undigested Food")): \(answerText(hasUndigestedFood))"
        ]

        let entry = HealthLogEntry(
            id: UUID(),
            type: .snapshot,
            categoryID: option.id,
            title: option.title,
            timestamp: movementTime,
            severity: BristolStoolGuide.severity(for: selectedStoolType),
            value: value,
            comments: detailLines.joined(separator: "\n")
        )
        onSave(entry)
        dismiss()
    }

    private func answerText(_ value: Bool?) -> String {
        guard let value else { return "--" }
        return localizedAppString(value ? "Yes" : "No")
    }
}

