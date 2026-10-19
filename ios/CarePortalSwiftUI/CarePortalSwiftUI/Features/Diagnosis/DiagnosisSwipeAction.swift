import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct DiagnosisSwipeAction: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let tint: Color
    let action: () -> Void
}

