import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct SleepSnapshotPrefill {
    let fellAsleepAt: Date
    let wokeUpAt: Date
    let quality: SleepRestQuality
    let wakingCount: Int
    let comments: String
}

