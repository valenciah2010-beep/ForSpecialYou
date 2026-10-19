import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct HealthInsightDailyCache: Codable {
    let dateKey: String
    let insights: [HealthInsight]
    let isUnavailable: Bool
}

