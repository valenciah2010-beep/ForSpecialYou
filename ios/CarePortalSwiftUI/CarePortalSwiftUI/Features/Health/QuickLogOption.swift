import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct QuickLogOption: Identifiable {
    let id: String
    let title: String
    let icon: String
    let tint: Color

    static let moodSnapshotOption = QuickLogOption(
        id: "mood",
        title: "Mood",
        icon: "face.smiling",
        tint: Color(red: 0.95, green: 0.52, blue: 0.61)
    )

    static let all: [QuickLogOption] = [
        QuickLogOption(id: "seizure", title: "Seizure Track", icon: "timer", tint: Color(red: 0.94, green: 0.31, blue: 0.29)),
        QuickLogOption(id: "meltdown", title: "Meltdown", icon: "exclamationmark.triangle.fill", tint: Color(red: 0.96, green: 0.74, blue: 0.24)),
        QuickLogOption(id: "stimming", title: "Stimming/Tics", icon: "waveform.path.ecg", tint: Color(red: 0.51, green: 0.69, blue: 0.96)),
        QuickLogOption(id: "accident", title: "Accident", icon: "drop.triangle.fill", tint: Color(red: 0.69, green: 0.61, blue: 0.91)),
        QuickLogOption(id: "deescalation", title: "De-escalation", icon: "hand.raised.fill", tint: Color(red: 0.43, green: 0.77, blue: 0.62)),
        QuickLogOption(id: "allergy", title: "Allergic Reaction", icon: "allergens.fill", tint: Color(red: 0.96, green: 0.58, blue: 0.43)),
        QuickLogOption(id: "pain", title: "Pain", icon: "cross.case.fill", tint: Color(red: 0.92, green: 0.41, blue: 0.47)),
        QuickLogOption(id: "skin", title: "Skin", icon: "bandage.fill", tint: Color(red: 0.95, green: 0.68, blue: 0.32)),
        QuickLogOption(id: "cyclicVomiting", title: "Cyclic Vomiting", icon: "arrow.triangle.2.circlepath", tint: Color(red: 0.23, green: 0.66, blue: 0.68)),
        QuickLogOption(id: "discomfort", title: "Discomfort", icon: "thermometer.medium", tint: Color(red: 0.88, green: 0.72, blue: 0.45)),
        QuickLogOption(id: "medsFood", title: "Medicine", icon: "pills.fill", tint: Color(red: 0.38, green: 0.75, blue: 0.55))
    ]

    static let defaultSelectionString = "seizure,meltdown,cyclicVomiting,medsFood"
    static let defaultSelectionIDs = defaultSelectionString.split(separator: ",").map(String.init)

    static func option(id: String) -> QuickLogOption? {
        all.first { $0.id == id }
    }
}

