import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct MedicationChecklistItem: Identifiable {
    let id: String
    let medication: MedicationSchedule
    let time: MedicationDayTime
    let dose: String
    let timeText: String
    let sortMinutes: Int
}

