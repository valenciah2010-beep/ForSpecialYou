import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct HealthLogEntry: Identifiable, Codable {
    enum LogType: String, Codable {
        case quickLog
        case snapshot
    }

    let id: UUID
    let type: LogType
    let categoryID: String
    let title: String
    let timestamp: Date
    let severity: Int
    let value: String
    let comments: String
    let imageData: Data?

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case categoryID
        case title
        case timestamp
        case severity
        case value
        case comments
        case imageData
    }

    init(
        id: UUID,
        type: LogType,
        categoryID: String,
        title: String,
        timestamp: Date,
        severity: Int,
        value: String,
        comments: String,
        imageData: Data? = nil
    ) {
        self.id = id
        self.type = type
        self.categoryID = categoryID
        self.title = title
        self.timestamp = timestamp
        self.severity = severity
        self.value = value
        self.comments = comments
        self.imageData = imageData
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(LogType.self, forKey: .type)
        categoryID = try container.decode(String.self, forKey: .categoryID)
        title = try container.decode(String.self, forKey: .title)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        severity = try container.decode(Int.self, forKey: .severity)
        value = try container.decode(String.self, forKey: .value)
        comments = try container.decode(String.self, forKey: .comments)
        imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
    }
}

