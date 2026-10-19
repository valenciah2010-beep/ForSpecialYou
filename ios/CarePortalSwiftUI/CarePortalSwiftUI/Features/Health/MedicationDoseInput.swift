import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct MedicationDoseInput: Identifiable {
    let id: String
    let label: String
    let time: MedicationDayTime
}

