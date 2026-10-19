import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct SkinLogEntrySheet: View {
    @Environment(\.dismiss) private var dismiss

    let option: QuickLogOption
    let onSave: (HealthLogEntry) -> Void

    @State private var timestamp = Date()
    @State private var selectedMealPhoto: PhotosPickerItem?
    @State private var isCameraPickerPresented = false
    @State private var photoData = Data()
    @State private var selectedSeverity: SkinSeverityLevel?
    @State private var selectedLocations: Set<String> = []
    @State private var selectedTriggers: Set<String> = []
    @State private var selectedSymptoms: Set<String> = []

    private let locationOptions = [
        "Face/Neck",
        "Torso",
        "Arms",
        "Legs",
        "Full Body"
    ]

    private let triggerOptions = [
        "New Food",
        "Medication",
        "Environmental/Outdoor",
        "Detergent/Soap",
        "Unknown"
    ]

    private let symptomOptions = [
        "Itching/Scratching",
        "Heat/Feverish skin",
        "Swelling",
        "Irritation/Crying"
    ]

    private var canSave: Bool {
        selectedSeverity != nil
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        photoCard

                        timestampCard

                        severityCard

                        if selectedSeverity == .severe {
                            severeReminder
                        }

                        skinChipSection(
                            icon: "mappin.and.ellipse",
                            title: "Location",
                            options: locationOptions,
                            selection: $selectedLocations
                        )

                        skinChipSection(
                            icon: "questionmark.circle",
                            title: "Suspected Trigger",
                            options: triggerOptions,
                            selection: $selectedTriggers
                        )

                        skinChipSection(
                            icon: "tag.fill",
                            title: "Symptom Tags",
                            options: symptomOptions,
                            selection: $selectedSymptoms
                        )
                    }
                    .padding(18)
                }

                StickyBottomSaveButton(
                    title: "Save Log",
                    tint: AppTheme.accent,
                    isDisabled: !canSave
                ) {
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
            .task(id: selectedMealPhoto) {
                await loadSelectedPhoto()
            }
            .fullScreenCover(isPresented: $isCameraPickerPresented) {
                CameraMealPhotoPicker { data in
                    photoData = compressedSkinPhotoData(data)
                }
                .ignoresSafeArea()
            }
        }
        .presentationDetents([.large])
    }

    private var photoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(localizedAppString("Skin Photo"), systemImage: "camera.fill")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.text)

                Spacer()
            }

            if let image = UIImage(data: photoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 170)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            HStack(spacing: 10) {
                Button {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        isCameraPickerPresented = true
                    }
                } label: {
                    Label(localizedAppString("Take Photo"), systemImage: "camera.fill")
                        .font(.subheadline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(UIImagePickerController.isSourceTypeAvailable(.camera) ? option.tint.opacity(0.16) : Color.gray.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))

                PhotosPicker(selection: $selectedMealPhoto, matching: .images) {
                    Label(localizedAppString("Upload Photo"), systemImage: "photo.on.rectangle")
                        .font(.subheadline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(option.tint.opacity(0.16))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .foregroundStyle(AppTheme.accent)
        }
        .skinSectionCard()
    }

    private var timestampCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "calendar.badge.clock")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 30, height: 30)
                .background(AppTheme.accent.opacity(0.1))
                .clipShape(Circle())

            Text(localizedAppString("Timestamp"))
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.text)

            Spacer(minLength: 4)

            DatePicker("", selection: $timestamp, displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(.compact)
                .fixedSize()

            DatePicker("", selection: $timestamp, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .datePickerStyle(.compact)
                .fixedSize()
        }
        .skinSectionCard()
    }

    private var severityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(localizedAppString("Severity Level"), systemImage: "gauge.with.dots.needle.50percent")
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.text)

            VStack(spacing: 9) {
                ForEach(SkinSeverityLevel.allCases) { severity in
                    Button {
                        selectedSeverity = selectedSeverity == severity ? nil : severity
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(severity.color)
                                .frame(width: 12, height: 12)
                                .padding(.top, 5)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(localizedAppString(severity.rawValue))
                                    .font(.subheadline.weight(.black))

                                Text(localizedAppString(severity.description))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(selectedSeverity == severity ? .white.opacity(0.86) : .secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()

                            Image(systemName: selectedSeverity == severity ? "checkmark.circle.fill" : "circle")
                                .font(.headline.weight(.bold))
                        }
                        .foregroundStyle(selectedSeverity == severity ? .white : AppTheme.text)
                        .padding(12)
                        .background(selectedSeverity == severity ? severity.color : AppTheme.fieldBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .skinSectionCard()
    }

    private var severeReminder: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 4) {
                Text(localizedAppString("Seek immediate medical attention"))
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)

                Text(localizedAppString("If prescribed, use an EpiPen and follow the emergency care plan."))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(Color(red: 0.86, green: 0.13, blue: 0.13))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func skinChipSection(
        icon: String,
        title: String,
        options: [String],
        selection: Binding<Set<String>>
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(localizedAppString(title), systemImage: icon)
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.text)

            FlowLayout(spacing: 8, rowSpacing: 8) {
                ForEach(options, id: \.self) { item in
                    CyclicVomitingOptionChip(
                        title: item,
                        isSelected: selection.wrappedValue.contains(item),
                        tint: option.tint
                    ) {
                        if selection.wrappedValue.contains(item) {
                            selection.wrappedValue.remove(item)
                        } else {
                            selection.wrappedValue.insert(item)
                        }
                    }
                }
            }
        }
        .skinSectionCard()
    }

    private func loadSelectedPhoto() async {
        guard let selectedMealPhoto else { return }

        do {
            if let data = try await selectedMealPhoto.loadTransferable(type: Data.self) {
                await MainActor.run {
                    photoData = compressedSkinPhotoData(data)
                    self.selectedMealPhoto = nil
                }
            }
        } catch {
            // Keep any already selected photo.
        }
    }

    private func compressedSkinPhotoData(_ data: Data) -> Data {
        if let image = UIImage(data: data),
           let jpegData = image.resizedForMealAnalysis(maxDimension: 900).jpegData(compressionQuality: 0.72) {
            return jpegData
        }

        return data
    }

    private func selectedText(_ values: Set<String>) -> String {
        values.isEmpty ? localizedAppString("Not selected") : values.sorted().map { localizedAppString($0) }.joined(separator: ", ")
    }

    private func save() {
        guard let selectedSeverity else { return }

        let comments = [
            "Timestamp: \(localizedDateString(timestamp, dateStyle: .medium, timeStyle: .short))",
            "Severity: \(localizedAppString(selectedSeverity.rawValue)) - \(localizedAppString(selectedSeverity.description))",
            "Locations: \(selectedText(selectedLocations))",
            "Suspected Trigger: \(selectedText(selectedTriggers))",
            "Symptoms: \(selectedText(selectedSymptoms))",
            photoData.isEmpty ? nil : "Photo attached"
        ]
        .compactMap { $0 }
        .joined(separator: "\n")

        let entry = HealthLogEntry(
            id: UUID(),
            type: .quickLog,
            categoryID: option.id,
            title: option.title,
            timestamp: timestamp,
            severity: selectedSeverity.score,
            value: localizedAppString(selectedSeverity.rawValue),
            comments: comments,
            imageData: photoData.isEmpty ? nil : photoData
        )

        onSave(entry)
        dismiss()
    }
}

