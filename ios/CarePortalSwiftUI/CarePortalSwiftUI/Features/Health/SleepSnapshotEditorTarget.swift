import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct SleepSnapshotEditorTarget: Identifiable {
    let option: SnapshotOption
    let existingEntry: HealthLogEntry?

    var id: String {
        existingEntry?.id.uuidString ?? "new-\(option.id)"
    }
}

