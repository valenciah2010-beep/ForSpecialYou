import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct SnapshotOption: Identifiable {
    let id: String
    let title: String
    let icon: String
    let value: String
    let detail: String
    let tint: Color
    let progress: Double

    var emptyCaption: String {
        switch id {
        case "sleep":
            return "Click to fill out sleep"
        case "digestion":
            return "Click to fill out gut and digestion"
        case "mood":
            return "Click to log mood"
        case "nutrition":
            return "Click to set nutrition goals"
        default:
            return "Click to fill out"
        }
    }

    var dashboardLabel: String {
        switch id {
        case "sleep":
            return "Sleep"
        case "digestion":
            return "Bowel Movement"
        case "mood":
            return "Mood"
        case "nutrition":
            return "Nutrition"
        default:
            return title
        }
    }

    static let all: [SnapshotOption] = [
        SnapshotOption(
            id: "sleep",
            title: "Sleep & Rest",
            icon: "moon.zzz.fill",
            value: "--",
            detail: "--",
            tint: Color(red: 0.34, green: 0.66, blue: 0.88),
            progress: 0.78
        ),
        SnapshotOption(
            id: "digestion",
            title: "Gut & Digestion",
            icon: "figure.core.training",
            value: "--",
            detail: "--",
            tint: Color(red: 0.45, green: 0.75, blue: 0.52),
            progress: 0.55
        ),
        SnapshotOption(
            id: "mood",
            title: "Mood",
            icon: "face.smiling",
            value: "--",
            detail: "--",
            tint: Color(red: 1.0, green: 0.78, blue: 0.28),
            progress: 0.5
        ),
        SnapshotOption(
            id: "nutrition",
            title: "Nutrition",
            icon: "leaf.fill",
            value: "--",
            detail: "--",
            tint: Color(red: 0.43, green: 0.77, blue: 0.62),
            progress: 0.75
        )
    ]

    static let measurements: [SnapshotOption] = [
        SnapshotOption(
            id: "height",
            title: "Height",
            icon: "ruler.fill",
            value: "--",
            detail: "--",
            tint: Color(red: 0.34, green: 0.66, blue: 0.88),
            progress: 0.5
        ),
        SnapshotOption(
            id: "weight",
            title: "Weight",
            icon: "scalemass.fill",
            value: "--",
            detail: "--",
            tint: Color(red: 0.43, green: 0.77, blue: 0.62),
            progress: 0.5
        )
    ]
}

