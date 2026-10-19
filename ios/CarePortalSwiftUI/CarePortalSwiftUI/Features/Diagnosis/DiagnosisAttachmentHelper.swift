import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

enum DiagnosisAttachmentHelper {
    static func loadPhotoData(from selectedItems: [PhotosPickerItem]) async -> [Data] {
        var loaded: [Data] = []

        for item in selectedItems {
            if let data = try? await item.loadTransferable(type: Data.self) {
                loaded.append(data)
            }
        }

        return loaded
    }

    static func photoAttachments(from dataItems: [Data], startingAt startIndex: Int) -> [DiagnosisAttachment] {
        dataItems.enumerated().map { offset, data in
            DiagnosisAttachment(
                kind: .photo,
                name: "\(localizedAppString("Photo")) \(startIndex + offset + 1)",
                data: compressedPhotoData(data)
            )
        }
    }

    static func compressedPhotoData(_ data: Data) -> Data {
        if let image = UIImage(data: data),
           let jpegData = image.resizedForMealAnalysis(maxDimension: 1000).jpegData(compressionQuality: 0.74) {
            return jpegData
        }

        return data
    }

    static func importedFiles(from result: Result<[URL], Error>) -> ([DiagnosisAttachment], String) {
        switch result {
        case .success(let urls):
            var attachments: [DiagnosisAttachment] = []
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

                attachments.append(DiagnosisAttachment(kind: .file, name: url.lastPathComponent, data: data))
            }

            if blockedVideoCount > 0 {
                return (attachments, localizedAppString("Videos cannot be uploaded. Please choose photos or supported documents."))
            }

            return (attachments, attachments.isEmpty ? "" : localizedAppString("File added."))
        case .failure:
            return ([], localizedAppString("Unable to import this file."))
        }
    }
}

