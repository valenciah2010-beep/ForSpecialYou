import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct DiagnosisOption: Identifiable {
    let id: String
    let title: String
    let emoji: String

    static let all: [DiagnosisOption] = [
        DiagnosisOption(id: "genetics", title: "Genetics", emoji: "🧬"),
        DiagnosisOption(id: "pediatricHealthClinic", title: "Pediatric Health Clinic (Early Screening)", emoji: "🩺"),
        DiagnosisOption(id: "developmentalBehavioral", title: "Developmental-Behavioral Pediatrics", emoji: "🧩"),
        DiagnosisOption(id: "childPsychiatryPsychology", title: "Child Psychiatry/Psychology", emoji: "🧠"),
        DiagnosisOption(id: "neurology", title: "Neurology", emoji: "⚡"),
        DiagnosisOption(id: "rehabilitationInterventions", title: "Rehabilitation / Interventions", emoji: "🏃"),
        DiagnosisOption(id: "gastroenterology", title: "Gastroenterology", emoji: "🍽️"),
        DiagnosisOption(id: "oralRelated", title: "Oral Related (Stomatology)", emoji: "🦷"),
        DiagnosisOption(id: "dermatology", title: "Dermatology", emoji: "🩹"),
        DiagnosisOption(id: "orthopedics", title: "Orthopedics", emoji: "🦴"),
        DiagnosisOption(id: "stomatology", title: "Otolaryngology (ENT)", emoji: "👂"),
        DiagnosisOption(id: "neurosurgery", title: "Neurosurgery", emoji: "🧠"),
        DiagnosisOption(id: "ophthalmology", title: "Ophthalmology", emoji: "👁️"),
        DiagnosisOption(id: "traditionalChineseMedicine", title: "Traditional Chinese Medicine", emoji: "🌿"),
        DiagnosisOption(id: "nutrition", title: "Nutrition", emoji: "🥗"),
        DiagnosisOption(id: "autismSpecialist", title: "Autism Specialist", emoji: "♾️"),
        DiagnosisOption(id: "other", title: "Other", emoji: "✨")
    ]

    static func option(id: String) -> DiagnosisOption? {
        all.first { $0.id == id }
    }
}

