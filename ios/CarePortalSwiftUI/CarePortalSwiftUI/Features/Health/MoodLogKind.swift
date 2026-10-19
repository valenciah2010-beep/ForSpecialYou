import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

enum MoodLogKind: String, CaseIterable, Identifiable {
    case currentEmotion = "Current Emotion"
    case todaysMood = "Today's Mood"

    var id: String { rawValue }
}

