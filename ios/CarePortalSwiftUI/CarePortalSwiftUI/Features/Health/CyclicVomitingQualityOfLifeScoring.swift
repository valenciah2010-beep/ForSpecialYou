import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

enum CyclicVomitingQualityOfLifeScoring {
    static func isAssessmentAvailable(for ageRange: String) -> Bool {
        ageRange == "13–18 years old"
            || ageRange == "8–12 years old"
            || ageRange == "5–7 years old"
            || ageRange == "2–4 years old"
    }

    static func sections(for ageRange: String) -> [(title: String, questions: [String])] {
        switch ageRange {
        case "8–12 years old":
            return childSections
        case "5–7 years old":
            return youngChildSections
        case "2–4 years old":
            return toddlerSections
        default:
            return teenSections
        }
    }

    static func summary(for ageRange: String, responses: [String: Int]) -> QualityOfLifeScoreSummary? {
        guard isAssessmentAvailable(for: ageRange), !responses.isEmpty else { return nil }
        let activeSections = sections(for: ageRange)
        let total = meanConvertedScore(for: activeSections.flatMap(\.questions), responses: responses)
        let physical = activeSections
            .first(where: { $0.title == "Physical Functioning" })
            .flatMap { meanConvertedScore(for: $0.questions, responses: responses) }
        let psychosocial = meanConvertedScore(
            for: activeSections.filter { $0.title != "Physical Functioning" }.flatMap(\.questions),
            responses: responses
        )

        return QualityOfLifeScoreSummary(
            total: scoreText(total),
            physical: scoreText(physical),
            psychosocial: scoreText(psychosocial)
        )
    }

    static func meanConvertedScore(for questions: [String], responses: [String: Int]) -> Double? {
        let scores = questions.compactMap { question -> Double? in
            guard let rawScore = responses[question] else { return nil }
            return convertedScaleScore(for: rawScore)
        }

        guard !scores.isEmpty else { return nil }
        return scores.reduce(0, +) / Double(scores.count)
    }

    static func convertedScaleScore(for rawScore: Int) -> Double {
        Double(4 - rawScore) * 25
    }

    static func scoreText(_ score: Double?) -> String {
        guard let score else { return "--" }
        if score.rounded() == score {
            return "\(Int(score))"
        }
        return String(format: "%.1f", score)
    }

    private static let teenSections: [(title: String, questions: [String])] = [
        (
            title: "Physical Functioning",
            questions: [
                "Walking more than one block",
                "Running",
                "Participating in sports activity or exercise",
                "Lifting something heavy",
                "Doing chores around the house"
            ]
        ),
        (
            title: "Emotional Functioning",
            questions: [
                "Feeling afraid or scared",
                "Feeling sad or blue",
                "Feeling angry",
                "Worrying about what will happen to him or her"
            ]
        ),
        (
            title: "Social Functioning",
            questions: [
                "Getting along with other teens",
                "Other teens not wanting to be his or her friend",
                "Getting teased by other teens"
            ]
        ),
        (
            title: "School Functioning",
            questions: [
                "Paying attention in class",
                "Forgetting things",
                "Keeping up with schoolwork"
            ]
        )
    ]

    private static let childSections: [(title: String, questions: [String])] = [
        (
            title: "Physical Functioning",
            questions: [
                "Walking more than one block",
                "Running",
                "Participating in sports activity or exercise",
                "Lifting something heavy",
                "Doing chores around the house"
            ]
        ),
        (
            title: "Emotional Functioning",
            questions: [
                "Feeling afraid or scared",
                "Feeling sad or blue",
                "Feeling angry",
                "Worrying about what will happen to him or her"
            ]
        ),
        (
            title: "Social Functioning",
            questions: [
                "Getting along with other children",
                "Other kids not wanting to be his or her friend",
                "Getting teased by other children"
            ]
        ),
        (
            title: "School Functioning",
            questions: [
                "Paying attention in class",
                "Forgetting things",
                "Keeping up with schoolwork"
            ]
        )
    ]

    private static let youngChildSections: [(title: String, questions: [String])] = [
        (
            title: "Physical Functioning",
            questions: [
                "Walking more than one block",
                "Running",
                "Participating in sports activity or exercise",
                "Lifting something heavy",
                "Doing chores, like picking up his or her toys"
            ]
        ),
        (
            title: "Emotional Functioning",
            questions: [
                "Feeling afraid or scared",
                "Feeling sad or blue",
                "Feeling angry",
                "Worrying about what will happen to him or her"
            ]
        ),
        (
            title: "Social Functioning",
            questions: [
                "Getting along with other children",
                "Other kids not wanting to be his or her friend",
                "Getting teased by other children"
            ]
        ),
        (
            title: "School Functioning",
            questions: [
                "Paying attention in class",
                "Forgetting things",
                "Keeping up with school activities"
            ]
        )
    ]

    private static let toddlerSections: [(title: String, questions: [String])] = [
        (
            title: "Physical Functioning",
            questions: [
                "Walking",
                "Running",
                "Participating in active play or exercise",
                "Lifting something heavy",
                "Helping to pick up his or her toys"
            ]
        ),
        (
            title: "Emotional Functioning",
            questions: [
                "Feeling afraid or scared",
                "Feeling sad or blue",
                "Feeling angry",
                "Worrying"
            ]
        ),
        (
            title: "Social Functioning",
            questions: [
                "Playing with other children",
                "Other kids not wanting to play with him or her",
                "Getting teased by other children"
            ]
        ),
        (
            title: "School Functioning",
            questions: [
                "Doing the same school activities as peers",
                "Missing school/daycare because of not feeling well",
                "Missing school/daycare to go to the doctor or hospital"
            ]
        )
    ]
}

