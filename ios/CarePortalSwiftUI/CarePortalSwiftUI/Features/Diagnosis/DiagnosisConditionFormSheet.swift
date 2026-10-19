import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct DiagnosisConditionFormSheet: View {
    @Environment(\.dismiss) private var dismiss

    let existingCondition: DiagnosisCondition?
    let onSave: (DiagnosisCondition) -> Void

    @State private var selectedCategoryIDs: Set<String>
    @State private var conditionName: String
    @State private var notes: String
    @State private var photos: [DiagnosisAttachment]
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var isCameraPresented = false
    @State private var isCategoryExpanded = false
    @State private var statusMessage = ""

    private var canSave: Bool {
        !conditionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var selectedCategoryText: String {
        let selected = DiagnosisOption.all
            .filter { selectedCategoryIDs.contains($0.id) }
            .map { "\($0.emoji) \(localizedAppString($0.title))" }

        return selected.isEmpty ? localizedAppString("Select category") : selected.joined(separator: ", ")
    }

    init(existingCondition: DiagnosisCondition? = nil, onSave: @escaping (DiagnosisCondition) -> Void) {
        self.existingCondition = existingCondition
        self.onSave = onSave
        self._selectedCategoryIDs = State(initialValue: Set(existingCondition?.categoryIDs ?? []))
        self._conditionName = State(initialValue: existingCondition?.name ?? "")
        self._notes = State(initialValue: existingCondition?.notes ?? "")
        self._photos = State(initialValue: existingCondition?.photos ?? [])
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 12) {
                            Button {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.86)) {
                                    isCategoryExpanded.toggle()
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(localizedAppString("Select category"))
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(.secondary)

                                        Text(selectedCategoryText)
                                            .font(.headline.weight(.semibold))
                                            .foregroundStyle(AppTheme.text)
                                            .lineLimit(2)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.down")
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(.secondary)
                                        .rotationEffect(.degrees(isCategoryExpanded ? 180 : 0))
                                }
                                .padding(14)
                                .background(AppTheme.fieldBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)

                            if isCategoryExpanded {
                                VStack(spacing: 8) {
                                    ForEach(DiagnosisOption.all) { option in
                                        Button {
                                            toggleCategory(option.id)
                                        } label: {
                                            HStack(spacing: 12) {
                                                Image(systemName: selectedCategoryIDs.contains(option.id) ? "checkmark.square.fill" : "square")
                                                    .font(.headline.weight(.semibold))
                                                    .foregroundStyle(selectedCategoryIDs.contains(option.id) ? AppTheme.accent : .secondary)

                                                Text(option.emoji)
                                                    .font(.title3)
                                                    .frame(width: 28)

                                                Text(localizedAppString(option.title))
                                                    .font(.subheadline.weight(.semibold))
                                                    .foregroundStyle(AppTheme.text)
                                                    .lineLimit(1)
                                                    .minimumScaleFactor(0.75)

                                                Spacer()
                                            }
                                            .padding(12)
                                            .background(selectedCategoryIDs.contains(option.id) ? AppTheme.accent.opacity(0.10) : AppTheme.panel)
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .diagnosisDetailCard()

                        VStack(alignment: .leading, spacing: 12) {
                            Text(localizedAppString("Condition Name"))
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.text)

                            TextField(localizedAppString("Enter condition name"), text: $conditionName)
                                .textInputAutocapitalization(.words)
                                .font(.headline.weight(.semibold))
                                .padding(14)
                                .background(AppTheme.fieldBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .diagnosisDetailCard()

                        VStack(alignment: .leading, spacing: 12) {
                            Text(localizedAppString("Notes"))
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.text)

                            TextField(localizedAppString("Add notes"), text: $notes, axis: .vertical)
                                .textInputAutocapitalization(.sentences)
                                .lineLimit(5...10)
                                .padding(14)
                                .background(AppTheme.fieldBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .diagnosisDetailCard()

                        VStack(alignment: .leading, spacing: 12) {
                            Text(localizedAppString("Photos"))
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.text)

                            HStack(spacing: 10) {
                                Button {
                                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                        isCameraPresented = true
                                    } else {
                                        statusMessage = localizedAppString("Camera unavailable on this device.")
                                    }
                                } label: {
                                    DiagnosisAttachmentAction(title: "Take Photo", icon: "camera.fill")
                                }
                                .buttonStyle(.plain)
                                .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))

                                PhotosPicker(selection: $selectedPhotos, matching: .images) {
                                    DiagnosisAttachmentAction(title: "Upload Photo", icon: "photo.on.rectangle")
                                }
                                .buttonStyle(.plain)
                            }

                            if !statusMessage.isEmpty {
                                Text(statusMessage)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }

                            if !photos.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(photos) { photo in
                                            DiagnosisConditionPhotoThumb(photo: photo) {
                                                photos.removeAll { $0.id == photo.id }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .diagnosisDetailCard()
                    }
                    .padding(18)
                }

                StickyBottomSaveButton(
                    title: "Save",
                    tint: AppTheme.accent,
                    isDisabled: !canSave
                ) {
                    save()
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(localizedAppString(existingCondition == nil ? "New Condition" : "Edit Condition"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ToolbarCloseButton {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
        .onChange(of: selectedPhotos) { _, newValue in
            guard !newValue.isEmpty else { return }
            Task {
                await loadSelectedPhotos(newValue)
            }
        }
        .fullScreenCover(isPresented: $isCameraPresented) {
            CameraMealPhotoPicker { data in
                addPhoto(data)
            }
            .ignoresSafeArea()
        }
    }

    private func toggleCategory(_ id: String) {
        if selectedCategoryIDs.contains(id) {
            selectedCategoryIDs.remove(id)
        } else {
            selectedCategoryIDs.insert(id)
        }
    }

    private func loadSelectedPhotos(_ selectedItems: [PhotosPickerItem]) async {
        var loaded: [Data] = []

        for item in selectedItems {
            if let data = try? await item.loadTransferable(type: Data.self) {
                loaded.append(data)
            }
        }

        await MainActor.run {
            addPhotos(loaded)
            selectedPhotos = []
        }
    }

    private func addPhoto(_ data: Data) {
        addPhotos([data])
    }

    private func addPhotos(_ dataItems: [Data]) {
        guard !dataItems.isEmpty else { return }

        for data in dataItems {
            let compressed = compressedConditionPhotoData(data)
            photos.append(
                DiagnosisAttachment(
                    kind: .photo,
                    name: "\(localizedAppString("Photo")) \(photos.count + 1)",
                    data: compressed
                )
            )
        }

        statusMessage = dataItems.count == 1
            ? localizedAppString("Photo added.")
            : String(format: localizedAppString("%d photos added."), dataItems.count)
    }

    private func compressedConditionPhotoData(_ data: Data) -> Data {
        if let image = UIImage(data: data),
           let jpegData = image.resizedForMealAnalysis(maxDimension: 1000).jpegData(compressionQuality: 0.74) {
            return jpegData
        }

        return data
    }

    private func save() {
        let condition = DiagnosisCondition(
            id: existingCondition?.id ?? UUID(),
            categoryIDs: DiagnosisOption.all.map(\.id).filter { selectedCategoryIDs.contains($0) },
            name: conditionName.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            photos: photos,
            createdAt: existingCondition?.createdAt ?? Date()
        )

        onSave(condition)
    }
}

