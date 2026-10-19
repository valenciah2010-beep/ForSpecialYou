import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct DiagnosisAttachment: Codable, Identifiable, Equatable {
    enum Kind: String, Codable {
        case photo
        case file
    }

    static let allowedFileTypes: [UTType] = [
        .image,
        .pdf,
        .plainText,
        .text,
        .rtf,
        .commaSeparatedText,
        .json,
        .xml
    ]

    static func isVideoFile(_ url: URL) -> Bool {
        let type = (try? url.resourceValues(forKeys: [.contentTypeKey]).contentType)
            ?? UTType(filenameExtension: url.pathExtension)

        return type?.conforms(to: .movie) == true
            || type?.conforms(to: .audiovisualContent) == true
    }

    let id: UUID
    let kind: Kind
    let name: String
    let data: Data
    let createdAt: Date

    init(id: UUID = UUID(), kind: Kind, name: String, data: Data, createdAt: Date = Date()) {
        self.id = id
        self.kind = kind
        self.name = name
        self.data = data
        self.createdAt = createdAt
    }
}

