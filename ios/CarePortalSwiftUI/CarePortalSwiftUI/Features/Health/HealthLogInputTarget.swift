import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

enum HealthLogInputTarget: Identifiable {
    case quickLog(QuickLogOption)
    case snapshot(SnapshotOption)

    var id: String {
        switch self {
        case .quickLog(let option):
            return "quick-\(option.id)"
        case .snapshot(let option):
            return "snapshot-\(option.id)"
        }
    }

    var title: String {
        switch self {
        case .quickLog(let option):
            return option.title
        case .snapshot(let option):
            return option.title
        }
    }

    var categoryID: String {
        switch self {
        case .quickLog(let option):
            return option.id
        case .snapshot(let option):
            return option.id
        }
    }

    var icon: String {
        switch self {
        case .quickLog(let option):
            return option.icon
        case .snapshot(let option):
            return option.icon
        }
    }

    var tint: Color {
        switch self {
        case .quickLog(let option):
            return option.tint
        case .snapshot(let option):
            return option.tint
        }
    }

    var logType: HealthLogEntry.LogType {
        switch self {
        case .quickLog:
            return .quickLog
        case .snapshot:
            return .snapshot
        }
    }

    var valuePrompt: String {
        switch self {
        case .quickLog:
            return "What happened?"
        case .snapshot:
            return "Snapshot value"
        }
    }
}

