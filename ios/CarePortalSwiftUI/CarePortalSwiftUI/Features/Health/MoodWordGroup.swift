import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct MoodWordGroup {
    let title: String
    let words: [String]

    static let positive = MoodWordGroup(
        title: "Calm / Positive states",
        words: ["Happy", "Calm", "Content", "Relaxed", "Playful", "Engaged", "Curious", "Focused", "Proud", "Safe"]
    )

    static let neutral = MoodWordGroup(
        title: "Mild / Neutral states",
        words: ["Okay", "Quiet", "Observant", "Tired", "Resting", "Neutral", "Thinking", "Daydreaming", "Slow-paced"]
    )

    static let difficult = MoodWordGroup(
        title: "Low / Difficult states",
        words: ["Sad", "Frustrated", "Overwhelmed", "Anxious", "Restless", "Upset", "Confused", "Withdrawn", "Sensitive", "Unsettled"]
    )

    static func group(for valence: Int) -> MoodWordGroup {
        if valence <= 3 {
            return .difficult
        }

        if valence == 4 {
            return .neutral
        }

        return .positive
    }
}

