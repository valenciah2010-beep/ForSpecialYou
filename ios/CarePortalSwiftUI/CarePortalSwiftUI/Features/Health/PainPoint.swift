import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct PainPoint: Identifiable, Equatable {
    let id = UUID()
    let side: PainBodySide
    let x: CGFloat
    let y: CGFloat
}

