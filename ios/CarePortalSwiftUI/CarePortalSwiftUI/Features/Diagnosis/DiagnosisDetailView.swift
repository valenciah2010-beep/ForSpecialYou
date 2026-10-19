import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct DiagnosisDetailView: View {
    let userID: Int
    let option: DiagnosisOption

    @AppStorage private var notes: String
    @AppStorage private var attachmentData: Data
    @AppStorage private var doctorVisitData: Data
    @AppStorage private var diagnosisNoteData: Data
    @AppStorage private var selectedDiagnosisOptionData: String
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var isCameraPresented = false
    @State private var isFileImporterPresented = false
    @State private var isDoctorVisitFormPresented = false
    @State private var editingDoctorVisit: DiagnosisDoctorVisit?
    @State private var editingDiagnosisNote: DiagnosisGeneralNote?
    @State private var statusMessage = ""

    init(userID: Int, option: DiagnosisOption) {
        self.userID = userID
        self.option = option
        self._notes = AppStorage(wrappedValue: "", "diagnosis.\(userID).\(option.id).notes")
        self._attachmentData = AppStorage(wrappedValue: Data(), "diagnosis.\(userID).\(option.id).attachments")
        self._doctorVisitData = AppStorage(wrappedValue: Data(), "diagnosis.\(userID).doctorVisits")
        self._diagnosisNoteData = AppStorage(wrappedValue: Data(), "diagnosis.\(userID).generalNotes")
        self._selectedDiagnosisOptionData = AppStorage(wrappedValue: "", "diagnosis.\(userID).selectedOptions")
    }

    private var attachments: [DiagnosisAttachment] {
        get {
            guard !attachmentData.isEmpty else { return [] }
            return (try? JSONDecoder().decode([DiagnosisAttachment].self, from: attachmentData)) ?? []
        }
        nonmutating set {
            attachmentData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    private var doctorVisits: [DiagnosisDoctorVisit] {
        get {
            guard !doctorVisitData.isEmpty else { return [] }
            return (try? JSONDecoder().decode([DiagnosisDoctorVisit].self, from: doctorVisitData)) ?? []
        }
        nonmutating set {
            doctorVisitData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    private var diagnosisNotes: [DiagnosisGeneralNote] {
        get {
            guard !diagnosisNoteData.isEmpty else { return [] }
            return (try? JSONDecoder().decode([DiagnosisGeneralNote].self, from: diagnosisNoteData)) ?? []
        }
        nonmutating set {
            diagnosisNoteData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    private var categoryTimelineItems: [DiagnosisCategoryTimelineItem] {
        let visitItems = doctorVisits
            .filter { $0.categoryIDs.contains(option.id) }
            .map { visit in
                DiagnosisCategoryTimelineItem(
                    id: "visit-\(visit.id.uuidString)",
                    sourceID: visit.id,
                    date: visit.date,
                    kind: .doctorVisit,
                    title: visit.displayTitle,
                    notePreview: visit.notes
                )
            }

        let noteItems = diagnosisNotes
            .filter { $0.categoryIDs.contains(option.id) }
            .map { note in
                DiagnosisCategoryTimelineItem(
                    id: "note-\(note.id.uuidString)",
                    sourceID: note.id,
                    date: note.date ?? note.createdAt,
                    kind: .note,
                    title: localizedAppString("Notes"),
                    notePreview: note.notes
                )
            }

        return (visitItems + noteItems).sorted { $0.date > $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 14) {
                    Text(option.emoji)
                        .font(.largeTitle)
                        .frame(width: 58, height: 58)
                        .background(AppTheme.accent.opacity(0.10))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 5) {
                        Text(localizedAppString(option.title))
                            .font(.title2.weight(.bold))
                            .foregroundStyle(AppTheme.text)

                        Text(localizedAppString("Medical diagnosis/history"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        DiagnosisSecondaryAddButton(title: "Doctor Visit", icon: "stethoscope", tint: Color(red: 0.19, green: 0.48, blue: 0.82)) {
                            isDoctorVisitFormPresented = true
                        }
                    }

                    if !categoryTimelineItems.isEmpty {
                        DiagnosisCategoryTimelineView(items: categoryTimelineItems) { item in
                            switch item.kind {
                            case .doctorVisit:
                                editingDoctorVisit = doctorVisits.first { $0.id == item.sourceID }
                            case .note:
                                editingDiagnosisNote = diagnosisNotes.first { $0.id == item.sourceID }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(localizedAppString("Notes"))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.text)

                    TextField(localizedAppString("Add diagnosis history, medical notes, evaluation details, or care-team updates"), text: $notes, axis: .vertical)
                        .textInputAutocapitalization(.sentences)
                        .lineLimit(8...14)
                        .padding(14)
                        .background(AppTheme.fieldBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .diagnosisDetailCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text(localizedAppString("Photos and Files"))
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

                    Button {
                        isFileImporterPresented = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "doc.fill")
                                .font(.headline.weight(.bold))
                            Text(localizedAppString("Upload File"))
                                .font(.headline.weight(.bold))
                            Spacer()
                        }
                        .foregroundStyle(AppTheme.accent)
                        .padding(14)
                        .background(AppTheme.accent.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    if !statusMessage.isEmpty {
                        Text(statusMessage)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    if attachments.isEmpty {
                        Text(localizedAppString("No photos or files added yet."))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(AppTheme.fieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    } else {
                        VStack(spacing: 10) {
                            ForEach(attachments) { attachment in
                                DiagnosisAttachmentRow(attachment: attachment) {
                                    deleteAttachment(attachment)
                                }
                            }
                        }
                    }
                }
                .diagnosisDetailCard()
            }
            .padding(20)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(localizedAppString(option.title))
        .navigationBarTitleDisplayMode(.inline)
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
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: DiagnosisAttachment.allowedFileTypes,
            allowsMultipleSelection: true
        ) { result in
            importFiles(result)
        }
        .sheet(isPresented: $isDoctorVisitFormPresented) {
            DiagnosisDoctorVisitFormSheet(initialCategoryID: option.id) { visit in
                var updated = doctorVisits
                updated.insert(visit, at: 0)
                doctorVisits = updated
                addDiagnosisOptions(visit.categoryIDs)
                isDoctorVisitFormPresented = false
            }
        }
        .sheet(item: $editingDoctorVisit) { visit in
            DiagnosisDoctorVisitFormSheet(existingVisit: visit) { editedVisit in
                var updated = doctorVisits
                if let index = updated.firstIndex(where: { $0.id == editedVisit.id }) {
                    updated[index] = editedVisit
                } else {
                    updated.insert(editedVisit, at: 0)
                }
                doctorVisits = updated
                addDiagnosisOptions(editedVisit.categoryIDs)
                editingDoctorVisit = nil
            }
        }
        .sheet(item: $editingDiagnosisNote) { note in
            DiagnosisGeneralNoteFormSheet(existingNote: note) { editedNote in
                var updated = diagnosisNotes
                if let index = updated.firstIndex(where: { $0.id == editedNote.id }) {
                    updated[index] = editedNote
                } else {
                    updated.insert(editedNote, at: 0)
                }
                diagnosisNotes = updated
                editingDiagnosisNote = nil
            }
        }
    }

    private func addDiagnosisOptions(_ ids: [String]) {
        var updatedIDs = Set(selectedDiagnosisOptionData.split(separator: ",").map(String.init))
        updatedIDs.formUnion(ids)
        selectedDiagnosisOptionData = DiagnosisOption.all
            .map(\.id)
            .filter { updatedIDs.contains($0) }
            .joined(separator: ",")
    }

    private func loadSelectedPhotos(_ photos: [PhotosPickerItem]) async {
        var loadedPhotoData: [Data] = []

        for photo in photos {
            do {
                if let data = try await photo.loadTransferable(type: Data.self) {
                    loadedPhotoData.append(data)
                }
            } catch {
                await MainActor.run {
                    statusMessage = localizedAppString("Unable to load this photo.")
                }
            }
        }

        await MainActor.run {
            if !loadedPhotoData.isEmpty {
                addPhotos(loadedPhotoData)
            }
            selectedPhotos = []
        }
    }

    private func addPhoto(_ data: Data) {
        addPhotos([data])
    }

    private func addPhotos(_ photos: [Data]) {
        var updated = attachments

        for data in photos.reversed() {
            let compressed = compressedDiagnosisPhotoData(data)
            updated.insert(
                DiagnosisAttachment(
                    kind: .photo,
                    name: "\(localizedAppString("Photo")) \(updated.filter { $0.kind == .photo }.count + 1)",
                    data: compressed
                ),
                at: 0
            )
        }

        attachments = updated
        statusMessage = photos.count == 1
            ? localizedAppString("Photo added.")
            : String(format: localizedAppString("%d photos added."), photos.count)
    }

    private func compressedDiagnosisPhotoData(_ data: Data) -> Data {
        if let image = UIImage(data: data),
           let jpegData = image.resizedForMealAnalysis(maxDimension: 1000).jpegData(compressionQuality: 0.74) {
            return jpegData
        }

        return data
    }

    private func importFiles(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            var updated = attachments
            var blockedVideoCount = 0

            for url in urls {
                guard !DiagnosisAttachment.isVideoFile(url) else {
                    blockedVideoCount += 1
                    continue
                }

                let didAccess = url.startAccessingSecurityScopedResource()
                defer {
                    if didAccess {
                        url.stopAccessingSecurityScopedResource()
                    }
                }

                guard let data = try? Data(contentsOf: url) else {
                    continue
                }

                updated.insert(
                    DiagnosisAttachment(kind: .file, name: url.lastPathComponent, data: data),
                    at: 0
                )
            }

            attachments = updated
            if blockedVideoCount > 0 {
                statusMessage = localizedAppString("Videos cannot be uploaded. Please choose photos or supported documents.")
            } else {
                statusMessage = urls.isEmpty ? "" : localizedAppString("File added.")
            }
        case .failure:
            statusMessage = localizedAppString("Unable to import this file.")
        }
    }

    private func deleteAttachment(_ attachment: DiagnosisAttachment) {
        attachments = attachments.filter { $0.id != attachment.id }
    }
}

