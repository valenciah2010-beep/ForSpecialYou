import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct DailyNotificationItem: Identifiable {
    let id = UUID()
    let notificationIdentifier: String
    let date: Date
    let title: String
    let body: String
    let isMedicineReminder: Bool
    let medicationChecklistID: String?

    var canMarkTaken: Bool {
        isMedicineReminder
    }

    var clearKey: String {
        medicationChecklistID ?? notificationIdentifier
    }
}

