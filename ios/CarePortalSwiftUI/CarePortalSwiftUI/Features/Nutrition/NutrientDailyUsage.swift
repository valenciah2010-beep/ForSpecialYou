import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct NutrientDailyUsage: Codable {
    var dateKey: String
    var uploadCount: Int
    var estimateCount: Int

    static func today() -> NutrientDailyUsage {
        NutrientDailyUsage(
            dateKey: MedicationCheckState.todayKey,
            uploadCount: 0,
            estimateCount: 0
        )
    }
}

