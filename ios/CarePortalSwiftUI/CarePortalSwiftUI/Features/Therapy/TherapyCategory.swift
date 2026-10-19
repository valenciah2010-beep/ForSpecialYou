import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct TherapyCategory: Identifiable {
    let id: String
    let title: String
    let icon: String
    let tint: Color
    let examples: String

    static let therapySession = TherapyCategory(
        id: "therapySession",
        title: "Therapy Session",
        icon: "figure.mind.and.body",
        tint: Color(red: 0.60, green: 0.78, blue: 0.92),
        examples: "Appointments, exercises, notes"
    )

    static let all: [TherapyCategory] = [
        TherapyCategory(
            id: "physical",
            title: "Physical",
            icon: "figure.walk",
            tint: Color(red: 0.89, green: 0.62, blue: 0.35),
            examples: "Balance, strength, stairs, movement"
        ),
        TherapyCategory(
            id: "occupational",
            title: "Occupational",
            icon: "hand.raised.fill",
            tint: Color(red: 0.44, green: 0.72, blue: 0.62),
            examples: "Fine motor, sensory, dressing, daily skills"
        ),
        TherapyCategory(
            id: "speech",
            title: "Speech",
            icon: "bubble.left.and.bubble.right.fill",
            tint: Color(red: 0.39, green: 0.62, blue: 0.88),
            examples: "Words, AAC, requests, social communication"
        ),
        TherapyCategory(
            id: "behavioral",
            title: "Behavioral/RDI",
            icon: "brain.head.profile",
            tint: Color(red: 0.83, green: 0.48, blue: 0.66),
            examples: "Transitions, regulation, coping, routines"
        ),
        TherapyCategory(
            id: "social",
            title: "Social",
            icon: "person.2.fill",
            tint: Color(red: 0.62, green: 0.57, blue: 0.86),
            examples: "Play, turn-taking, peer interaction"
        ),
        TherapyCategory(
            id: "feeding",
            title: "Feeding",
            icon: "fork.knife",
            tint: Color(red: 0.50, green: 0.73, blue: 0.48),
            examples: "Textures, chewing, new foods, hydration"
        )
    ]

    static func category(id: String) -> TherapyCategory? {
        ([therapySession] + all).first { $0.id == id }
    }
}

