import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct DiagnosisGeneralNoteFormSheet: View {
    @Environment(\.dismiss) private var dismiss

    let existingNote: DiagnosisGeneralNote?
    let onSave: (DiagnosisGeneralNote) -> Void

    @State private var selectedCategoryIDs: Set<String>
    @State private var includesDate: Bool
    @State private var noteDate: Date
    @State private var notes: String
    @State private var attachments: [DiagnosisAttachment]
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var isCategoryExpanded = false
    @State private var isCameraPresented = false
    @State private var isFileImporterPresented = false
    @State private var statusMessage = ""

    private var canSave: Bool {
        !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(
        initialCategoryID: String? = nil,
        existingNote: DiagnosisGeneralNote? = nil,
        onSave: @escaping (DiagnosisGeneralNote) -> Void
    ) {
        self.existingNote = existingNote
        self.onSave = onSave
        self._selectedCategoryIDs = State(initialValue: Set(existingNote?.categoryIDs ?? initialCategoryID.map { [$0] } ?? []))
        self._includesDate = State(initialValue: existingNote?.date != nil)
        self._noteDate = State(initialValue: existingNote?.date ?? Date())
        self._notes = State(initialValue: existingNote?.notes ?? "")
        self._attachments = State(initialValue: existingNote?.attachments ?? [])
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        DiagnosisCategoryDropdown(selectedCategoryIDs: $selectedCategoryIDs, isExpanded: $isCategoryExpanded)
                            .diagnosisDetailCard()

                        VStack(alignment: .leading, spacing: 12) {
                            Toggle(localizedAppString("Add date"), isOn: $includesDate)
                                .font(.headline.weight(.bold))
                                .tint(AppTheme.accent)

                            if includesDate {
                                DatePicker(localizedAppString("Date"), selection: $noteDate, displayedComponents: [.date])
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .padding(14)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(AppTheme.fieldBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }
                        .diagnosisDetailCard()

                        DiagnosisNotesInputCard(notes: $notes, placeholder: "Add note details")

                        DiagnosisRecordAttachmentCard(
                            attachments: attachments,
                            statusMessage: statusMessage,
                            onTakePhoto: openCamera,
                            onUploadFile: { isFileImporterPresented = true },
                            selectedPhotos: $selectedPhotos,
                            onDelete: deleteAttachment
                        )
                    }
                    .padding(18)
                }

                StickyBottomSaveButton(title: "Save", tint: AppTheme.accent, isDisabled: !canSave) {
                    save()
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(localizedAppString(existingNote == nil ? "Notes" : "Edit Notes"))
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
                let loaded = await DiagnosisAttachmentHelper.loadPhotoData(from: newValue)
                await MainActor.run {
                    addPhotos(loaded)
                    selectedPhotos = []
                }
            }
        }
        .fullScreenCover(isPresented: $isCameraPresented) {
            CameraMealPhotoPicker { data in
                addPhotos([data])
            }
            .ignoresSafeArea()
        }
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: DiagnosisAttachment.allowedFileTypes,
            allowsMultipleSelection: true
        ) { result in
            importFiles(result)
        }
    }

    private func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            isCameraPresented = true
        } else {
            statusMessage = localizedAppString("Camera unavailable on this device.")
        }
    }

    private func addPhotos(_ dataItems: [Data]) {
        guard !dataItems.isEmpty else { return }
        let photoCount = attachments.filter { $0.kind == .photo }.count
        attachments.append(contentsOf: DiagnosisAttachmentHelper.photoAttachments(from: dataItems, startingAt: photoCount))
        statusMessage = dataItems.count == 1
            ? localizedAppString("Photo added.")
            : String(format: localizedAppString("%d photos added."), dataItems.count)
    }

    private func importFiles(_ result: Result<[URL], Error>) {
        let imported = DiagnosisAttachmentHelper.importedFiles(from: result)
        attachments.append(contentsOf: imported.0)
        statusMessage = imported.1
    }

    private func deleteAttachment(_ attachment: DiagnosisAttachment) {
        attachments.removeAll { $0.id == attachment.id }
    }

    private func save() {
        onSave(
            DiagnosisGeneralNote(
                id: existingNote?.id ?? UUID(),
                categoryIDs: DiagnosisOption.all.map(\.id).filter { selectedCategoryIDs.contains($0) },
                date: includesDate ? noteDate : nil,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                attachments: attachments,
                createdAt: existingNote?.createdAt ?? Date()
            )
        )
    }
}

