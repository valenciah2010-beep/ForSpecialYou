import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct DiagnosisDoctorVisitFormSheet: View {
    @Environment(\.dismiss) private var dismiss

    let existingVisit: DiagnosisDoctorVisit?
    let onSave: (DiagnosisDoctorVisit) -> Void

    @State private var selectedCategoryIDs: Set<String>
    @State private var visitTitle: String
    @State private var doctorName: String
    @State private var clinicLocation: String
    @State private var visitDate: Date
    @State private var notes: String
    @State private var attachments: [DiagnosisAttachment]
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var isCategoryExpanded = false
    @State private var isCameraPresented = false
    @State private var isFileImporterPresented = false
    @State private var statusMessage = ""

    private var canSave: Bool {
        !visitTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !doctorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(
        initialCategoryID: String? = nil,
        existingVisit: DiagnosisDoctorVisit? = nil,
        onSave: @escaping (DiagnosisDoctorVisit) -> Void
    ) {
        self.existingVisit = existingVisit
        self.onSave = onSave
        self._selectedCategoryIDs = State(initialValue: Set(existingVisit?.categoryIDs ?? initialCategoryID.map { [$0] } ?? []))
        self._visitTitle = State(initialValue: existingVisit?.title ?? "")
        self._doctorName = State(initialValue: existingVisit?.doctorName ?? "")
        self._clinicLocation = State(initialValue: existingVisit?.clinicLocation ?? "")
        self._visitDate = State(initialValue: existingVisit?.date ?? Date())
        self._notes = State(initialValue: existingVisit?.notes ?? "")
        self._attachments = State(initialValue: existingVisit?.attachments ?? [])
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(localizedAppString("Title:"))
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.text)

                            TextField(localizedAppString("Enter title"), text: $visitTitle)
                                .textInputAutocapitalization(.words)
                                .font(.headline.weight(.semibold))
                                .padding(14)
                                .background(AppTheme.fieldBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .diagnosisDetailCard()

                        VStack(alignment: .leading, spacing: 12) {
                            DiagnosisCategoryDropdown(selectedCategoryIDs: $selectedCategoryIDs, isExpanded: $isCategoryExpanded)

                            HStack(spacing: 12) {
                                Text(localizedAppString("Date of Visit"))
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(AppTheme.text)

                                Spacer()

                                DatePicker(localizedAppString("Date of Visit"), selection: $visitDate, displayedComponents: [.date])
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                            }
                            .padding(14)
                            .background(AppTheme.fieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .diagnosisDetailCard()

                        VStack(alignment: .leading, spacing: 12) {
                            TextField(localizedAppString("Enter doctor name"), text: $doctorName)
                                .textInputAutocapitalization(.words)
                                .font(.headline.weight(.semibold))
                                .padding(14)
                                .background(AppTheme.fieldBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                            TextField(localizedAppString("Enter clinic or hospital"), text: $clinicLocation)
                                .textInputAutocapitalization(.words)
                                .font(.headline.weight(.semibold))
                                .padding(14)
                                .background(AppTheme.fieldBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .diagnosisDetailCard()

                        DiagnosisNotesInputCard(notes: $notes, placeholder: "Add visit notes")

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
            .navigationTitle(localizedAppString(existingVisit == nil ? "Doctor Visit" : "Edit Doctor Visit"))
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
            DiagnosisDoctorVisit(
                id: existingVisit?.id ?? UUID(),
                categoryIDs: DiagnosisOption.all.map(\.id).filter { selectedCategoryIDs.contains($0) },
                title: visitTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                doctorName: doctorName.trimmingCharacters(in: .whitespacesAndNewlines),
                clinicLocation: clinicLocation.trimmingCharacters(in: .whitespacesAndNewlines),
                date: visitDate,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                attachments: attachments,
                createdAt: existingVisit?.createdAt ?? Date()
            )
        )
    }
}

