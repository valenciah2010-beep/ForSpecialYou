import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct DiagnosisAttachmentRow: View {
    let attachment: DiagnosisAttachment
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if attachment.kind == .photo, let image = UIImage(data: attachment.data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 54, height: 54)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                Image(systemName: "doc.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 54, height: 54)
                    .background(AppTheme.accent.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(attachment.name)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.text)
                    .lineLimit(1)

                Text(localizedDateString(attachment.createdAt, dateStyle: .medium, timeStyle: .short))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.red.opacity(0.85))
                    .frame(width: 36, height: 36)
                    .background(Color.red.opacity(0.10))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(AppTheme.fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

