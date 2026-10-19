import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct DailyNotificationDismissState: Codable, Equatable {
    var dateKey: String
    var clearedIDs: [String]
}

