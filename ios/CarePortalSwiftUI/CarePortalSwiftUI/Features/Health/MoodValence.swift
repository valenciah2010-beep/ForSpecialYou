import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct MoodValence: Identifiable {
    let id: Int
    let title: String

    static let all: [MoodValence] = [
        MoodValence(id: 1, title: "Very unpleasant"),
        MoodValence(id: 2, title: "Unpleasant"),
        MoodValence(id: 3, title: "Slightly unpleasant"),
        MoodValence(id: 4, title: "Neutral"),
        MoodValence(id: 5, title: "Slightly pleasant"),
        MoodValence(id: 6, title: "Pleasant"),
        MoodValence(id: 7, title: "Very pleasant")
    ]

    static func title(for value: Int) -> String {
        all.first { $0.id == value }?.title ?? "Neutral"
    }
}

