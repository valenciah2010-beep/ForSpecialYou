import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct DiagnosisRecordAttachmentCard: View {
    let attachments: [DiagnosisAttachment]
    let statusMessage: String
    let onTakePhoto: () -> Void
    let onUploadFile: () -> Void
    @Binding var selectedPhotos: [PhotosPickerItem]
    let onDelete: (DiagnosisAttachment) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localizedAppString("Documents and Photos"))
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.text)

            HStack(spacing: 10) {
                Button(action: onTakePhoto) {
                    DiagnosisAttachmentAction(title: "Take Photo", icon: "camera.fill")
                }
                .buttonStyle(.plain)
                .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))

                PhotosPicker(selection: $selectedPhotos, matching: .images) {
                    DiagnosisAttachmentAction(title: "Upload Photo", icon: "photo.on.rectangle")
                }
                .buttonStyle(.plain)
            }

            Button(action: onUploadFile) {
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
                            onDelete(attachment)
                        }
                    }
                }
            }
        }
        .diagnosisDetailCard()
    }
}

