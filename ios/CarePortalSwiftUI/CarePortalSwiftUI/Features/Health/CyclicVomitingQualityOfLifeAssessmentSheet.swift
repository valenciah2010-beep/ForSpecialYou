import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct CyclicVomitingQualityOfLifeAssessmentSheet: View {
    @Environment(\.dismiss) private var dismiss

    let ageRange: String
    let tint: Color
    let onSave: ([String: Int]) -> Void
    @State private var teenResponses: [String: Int] = [:]
    @State private var collapsedTeenSections: Set<String> = []

    init(
        ageRange: String,
        tint: Color,
        savedResponses: [String: Int],
        onSave: @escaping ([String: Int]) -> Void
    ) {
        self.ageRange = ageRange
        self.tint = tint
        self.onSave = onSave
        self._teenResponses = State(initialValue: savedResponses)
    }

    private let responseOptions = [
        (label: "Never", value: 0),
        (label: "Almost Never", value: 1),
        (label: "Sometimes", value: 2),
        (label: "Often", value: 3),
        (label: "Almost Always", value: 4)
    ]

    private let teenSections: [(title: String, questions: [String])] = [
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

    private let childSections: [(title: String, questions: [String])] = [
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

    private let youngChildSections: [(title: String, questions: [String])] = [
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

    private let toddlerSections: [(title: String, questions: [String])] = [
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

    private var isClickableQualityAssessment: Bool {
        CyclicVomitingQualityOfLifeScoring.isAssessmentAvailable(for: ageRange)
    }

    private var activeAssessmentSections: [(title: String, questions: [String])] {
        CyclicVomitingQualityOfLifeScoring.sections(for: ageRange)
    }

    private var activeAssessmentInstruction: String {
        ageRange == "8–12 years old" || ageRange == "5–7 years old" || ageRange == "2–4 years old"
            ? "In the past ONE month, how much of a problem has your child had with ..."
            : "In the past ONE month, how much of a problem has your teen had with ..."
    }

    private var activeAssessmentFootnote: String? {
        ageRange == "2–4 years old"
            ? "Please complete this section if your child attends school or daycare"
            : nil
    }

    private var assessmentTitle: String {
        switch ageRange {
        case "13–18 years old":
            "Teen Quality of Life Assessment"
        case "8–12 years old":
            "Child Quality of Life Assessment"
        case "5–7 years old":
            "Young Child Quality of Life Assessment"
        case "2–4 years old":
            "Toddler Quality of Life Assessment"
        case "1–12 months":
            "Infant Quality of Life Assessment"
        default:
            "Quality of Life Assessment"
        }
    }

    private var assessmentRows: [String] {
        switch ageRange {
        case "13–18 years old":
            ["Physical comfort", "School and daily activities", "Friends and social participation", "Mood, worry, and independence"]
        case "8–12 years old":
            ["Physical comfort", "School or learning routines", "Play and peer interaction", "Mood and family routines"]
        case "5–7 years old":
            ["Eating and sleep comfort", "Play and movement", "Preschool or school participation", "Caregiver-observed mood"]
        case "2–4 years old":
            ["Feeding and sleep routines", "Play and movement", "Communication of discomfort", "Parent-observed daily burden"]
        case "1–12 months":
            ["Feeding comfort", "Sleep and soothing", "Vomiting impact on care routines", "Parent-observed distress"]
        default:
            ["Daily comfort", "Activity participation", "Family routines", "Mood or distress"]
        }
    }

    private var teenAnsweredCount: Int {
        teenResponses.count
    }

    private var teenTotalQuestionCount: Int {
        activeAssessmentSections.reduce(0) { total, section in total + section.questions.count }
    }

    private var teenScoreText: String {
        scoreText(totalScaleScore)
    }

    private var totalScaleScore: Double? {
        meanConvertedScore(for: activeAssessmentSections.flatMap(\.questions))
    }

    private var physicalHealthScore: Double? {
        guard let physicalSection = activeAssessmentSections.first(where: { $0.title == "Physical Functioning" }) else {
            return nil
        }

        return meanConvertedScore(for: physicalSection.questions)
    }

    private var psychosocialHealthScore: Double? {
        let psychosocialQuestions = activeAssessmentSections
            .filter { $0.title != "Physical Functioning" }
            .flatMap(\.questions)
        return meanConvertedScore(for: psychosocialQuestions)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if isClickableQualityAssessment {
                        Text(localizedAppString(ageRange))
                            .font(.title3.weight(.black))
                            .foregroundStyle(tint)
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(localizedAppString(assessmentTitle))
                                .font(.title3.weight(.black))
                                .foregroundStyle(AppTheme.text)

                            Text(localizedAppString(ageRange))
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(tint)
                        }
                    }

                    if isClickableQualityAssessment {
                        teenAssessment
                    } else {
                        placeholderAssessment
                    }

                    Spacer(minLength: 0)
                }
                .padding(20)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(localizedAppString("Done")) {
                        onSave(teenResponses)
                        dismiss()
                    }
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(tint)
                }
            }
        }
    }

    private var teenAssessment: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(localizedAppString(activeAssessmentInstruction))
                .font(.headline.weight(.semibold))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("\(teenAnsweredCount)/\(teenTotalQuestionCount)", systemImage: "checkmark.circle.fill")
                    Spacer()
                    Text("0-100")
                }
                .font(.caption.weight(.black))
                .foregroundStyle(tint)

                HStack(spacing: 8) {
                    qualityScorePill(title: "Total Score", value: teenScoreText)
                    qualityScorePill(title: "Physical Health", value: scoreText(physicalHealthScore))
                    qualityScorePill(title: "Psychosocial", value: scoreText(psychosocialHealthScore))
                }
            }
            .padding(10)
            .background(tint.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            ForEach(activeAssessmentSections, id: \.title) { section in
                if section.title == "School Functioning", let activeAssessmentFootnote {
                    Text(localizedAppString(activeAssessmentFootnote))
                        .font(.subheadline.weight(.black))
                        .italic()
                        .foregroundStyle(AppTheme.text)
                        .fixedSize(horizontal: false, vertical: true)
                }

                teenSectionCard(title: section.title, questions: section.questions)
            }
        }
    }

    private func teenSectionCard(title: String, questions: [String]) -> some View {
        let isCollapsed = collapsedTeenSections.contains(title)

        return VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.86)) {
                    if isCollapsed {
                        collapsedTeenSections.remove(title)
                    } else {
                        collapsedTeenSections.insert(title)
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Text(localizedAppString(title))
                        .font(.headline.weight(.black))
                        .foregroundStyle(AppTheme.text)

                    Spacer()

                    Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if !isCollapsed {
                ForEach(Array(questions.enumerated()), id: \.element) { index, question in
                    teenQuestionRow(
                        number: index + 1,
                        question: question
                    )
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func teenQuestionRow(number: Int, question: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(number). \(localizedAppString(question))")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.text)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 5) {
                ForEach(responseOptions, id: \.value) { option in
                    Button {
                        teenResponses[question] = option.value
                    } label: {
                        VStack(spacing: 3) {
                            Text(localizedAppString(option.label))
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)

                            Text("\(option.value)")
                                .font(.caption.weight(.black))
                        }
                        .foregroundStyle(teenResponses[question] == option.value ? .white : tint)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(teenResponses[question] == option.value ? tint : tint.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(10)
        .background(AppTheme.fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func qualityScorePill(title: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(localizedAppString(title))
                .font(.caption2.weight(.black))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.65)

            Text(value)
                .font(.subheadline.weight(.black))
                .foregroundStyle(AppTheme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.white.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
    }

    private func meanConvertedScore(for questions: [String]) -> Double? {
        CyclicVomitingQualityOfLifeScoring.meanConvertedScore(for: questions, responses: teenResponses)
    }

    private func convertedScaleScore(for rawScore: Int) -> Double {
        CyclicVomitingQualityOfLifeScoring.convertedScaleScore(for: rawScore)
    }

    private func scoreText(_ score: Double?) -> String {
        CyclicVomitingQualityOfLifeScoring.scoreText(score)
    }

    private var placeholderAssessment: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localizedAppString("Use this space for the matching quality of life form for the selected age range."))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 10) {
                ForEach(assessmentRows, id: \.self) { row in
                    HStack(spacing: 10) {
                        Image(systemName: "checklist")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(tint)
                            .frame(width: 28, height: 28)
                            .background(tint.opacity(0.14))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        Text(localizedAppString(row))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(AppTheme.text)

                        Spacer()
                    }
                    .padding(12)
                    .background(AppTheme.fieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }
}

