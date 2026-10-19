import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct CyclicVomitingLogSheet: View {
    @Environment(\.dismiss) private var dismiss

    let option: QuickLogOption
    let userID: Int
    let onSave: (HealthLogEntry) -> Void
    @AppStorage private var backgroundData: Data
    @AppStorage private var progressData: Data
    @AppStorage private var patternsData: Data

    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var hospitalized: Bool?
    @State private var selectedTriggers: Set<String> = []
    @State private var otherTriggers = ""
    @State private var selectedBeforeSymptoms: Set<String> = []
    @State private var otherBeforeSymptoms = ""
    @State private var selectedDuringSymptoms: Set<String> = []
    @State private var otherDuringSymptoms = ""
    @State private var selectedRecoverySymptoms: Set<String> = []
    @State private var otherRecoverySymptoms = ""
    @State private var vomitingActsPerDay = 1
    @State private var selectedMedications: Set<String> = []
    @State private var otherMedication = ""
    @State private var collapsedFormSections: Set<String> = []
    @State private var didLoadBackground = false
    @State private var didLoadProgress = false
    @State private var didLoadPatterns = false
    @State private var progressMessage = ""
    @State private var patternsMessage = ""
    @State private var selectedFamilyHistory: Set<String> = []
    @State private var selectedSurgicalHistory: Set<String> = []
    @State private var otherSurgery = ""
    @State private var onsetYear = ""
    @State private var onsetMonth = ""
    @State private var selectedComorbidities: Set<String> = []
    @State private var metabolismName = ""
    @State private var otherComorbidity = ""
    @State private var hospitalizedAtBeijingHospital: Bool?
    @State private var selectedCurrentBackgroundMedications: Set<String> = []
    @State private var otherCurrentBackgroundMedication = ""
    @State private var hadAdverseDrugReaction: Bool?
    @State private var adverseDrugReactionDetails = ""
    @State private var selectedPastMedications: Set<String> = []
    @State private var otherPastMedication = ""
    @State private var episodesPastYear = ""
    @State private var episodeInterval = ""
    @State private var episodeDuration = ""
    @State private var selectedHistoricalTriggers: Set<String> = []
    @State private var otherHistoricalTriggers = ""
    @State private var selectedProdromalSymptoms: Set<String> = []
    @State private var otherProdromalSymptoms = ""
    @State private var selectedEpisodeSymptoms: Set<String> = []
    @State private var otherEpisodeSymptoms = ""
    @State private var selectedPostdromalSymptoms: Set<String> = []
    @State private var otherPostdromalSymptoms = ""
    @State private var childHeightCm = ""
    @State private var childHeightUnit = "cm"
    @State private var childWeightKg = ""
    @State private var childWeightUnit = "Kg"
    @State private var qualityOfLifeAgeGroup = ""
    @State private var qualityOfLifeResponses: [String: Int] = [:]
    @State private var isQualityOfLifeAssessmentPresented = false
    @State private var isQualityOfLifeInfoPresented = false

    init(option: QuickLogOption, userID: Int, onSave: @escaping (HealthLogEntry) -> Void) {
        self.option = option
        self.userID = userID
        self.onSave = onSave
        self._backgroundData = AppStorage(wrappedValue: Data(), "health.\(userID).cyclicVomitingBackground")
        self._progressData = AppStorage(wrappedValue: Data(), "health.\(userID).cyclicVomitingProgress")
        self._patternsData = AppStorage(wrappedValue: Data(), "health.\(userID).cyclicVomitingPatterns")
    }

    private let familyHistoryOptions = [
        "Migraine",
        "Abdominal migraine",
        "Recurrent vomiting",
        "Motion sickness (carsick, seasick, or airsick)",
        "Functional abdominal pain or recurrent unexplained abdominal pain",
        "None"
    ]
    private let surgicalHistoryOptions = [
        "Post-tracheoesophageal fistula surgery",
        "Post-esophageal hiatal hernia surgery",
        "Post-congenital heart disease surgery",
        "Post-tethered cord syndrome surgery",
        "Post-fundoplication",
        "Post-Hirschsprung's disease surgery",
        "None"
    ]
    private let comorbidityOptions = [
        "Epilepsy",
        "Tourette syndrome",
        "Coffin-Siris syndrome",
        "Klinefelter syndrome",
        "Inborn errors of metabolism",
        "Celiac disease",
        "Inflammatory bowel disease",
        "None of the above"
    ]
    private let triggerOptions = [
        "Post-respiratory tract infection",
        "Post-improper diet",
        "After riding in a car or other vehicles",
        "Post-emotional stress/stimulation",
        "Menstrual period",
        "None of the above triggers"
    ]
    private let beforeSymptomOptions = [
        "Nausea",
        "Pallor",
        "Sweating",
        "Lethargy/Somnolence",
        "Hot flashes",
        "Headache",
        "Abdominal pain",
        "None of the above symptoms"
    ]
    private let duringSymptomOptions = [
        "Nausea",
        "Abdominal pain",
        "Diarrhea",
        "Anorexia",
        "Headache",
        "Photophobia",
        "Phonophobia",
        "Vertigo",
        "None of the above symptoms"
    ]
    private let recoverySymptomOptions = [
        "Drowsiness",
        "Deep sleep",
        "Abdominal pain",
        "Nausea",
        "Headache",
        "Dizziness",
        "None of the above symptoms"
    ]
    private let medicationOptions = [
        "Cyproheptadine",
        "Amitriptyline",
        "Propranolol",
        "Aprepitant",
        "Sodium valproate",
        "Phenobarbital",
        "Topiramate",
        "Coenzyme Q10",
        "L-carnitine",
        "Omeprazole",
        "None of the above medications have been used",
        "None (medication has now been discontinued)"
    ]
    private let pastMedicationOptions = [
        "Cyproheptadine",
        "Amitriptyline",
        "Propranolol",
        "Aprepitant",
        "Sodium valproate",
        "Phenobarbital",
        "Topiramate",
        "Coenzyme Q10",
        "L-carnitine",
        "Omeprazole",
        "None of the above medications have been used"
    ]
    private let episodeMedicationOptions = [
        "Cyproheptadine",
        "Amitriptyline",
        "Propranolol",
        "Aprepitant",
        "Sodium valproate",
        "Phenobarbital",
        "Topiramate",
        "Coenzyme Q10",
        "L-carnitine",
        "Omeprazole",
        "None"
    ]
    private let episodesPastYearOptions = [
        "< 4 times/year",
        "≥ 4 times/year",
        "No episodes"
    ]
    private let episodeIntervalOptions = [
        "> 2 months",
        "≤ 2 months"
    ]
    private let episodeDurationOptions = [
        "≤ 2 days",
        "> 2 days"
    ]
    private let baselineProdromalSymptomOptions = [
        "Nausea",
        "Pallor (pale face)",
        "Sweating",
        "Lethargy/Somnolence",
        "Hot flashes",
        "Headache",
        "Abdominal pain",
        "None of the above symptoms"
    ]
    private let baselineDuringSymptomOptions = [
        "Nausea",
        "Abdominal pain",
        "Diarrhea",
        "Anorexia (loss of appetite)",
        "Headache",
        "Photophobia",
        "Phonophobia",
        "Vertigo",
        "None of the above symptoms"
    ]
    private let qualityOfLifeAgeOptions = [
        "13–18 years old",
        "8–12 years old",
        "5–7 years old",
        "2–4 years old",
        "1–12 months"
    ]

    private var isQualityOfLifeAssessmentAvailable: Bool {
        CyclicVomitingQualityOfLifeScoring.isAssessmentAvailable(for: qualityOfLifeAgeGroup)
    }

    private var qualityOfLifeScoreSummary: QualityOfLifeScoreSummary? {
        CyclicVomitingQualityOfLifeScoring.summary(
            for: qualityOfLifeAgeGroup,
            responses: qualityOfLifeResponses
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            NavigationLink {
                                backgroundPage
                            } label: {
                                CyclicVomitingNavigationCard(
                                    title: "Background",
                                    icon: "person.text.rectangle.fill",
                                    tint: option.tint
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink {
                                vomitingPatternPage
                            } label: {
                                CyclicVomitingNavigationCard(
                                    title: "Vomiting Patterns",
                                    icon: "waveform.path.ecg.rectangle.fill",
                                    tint: option.tint
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        vomitingPatternForm
                    }
                    .padding(18)
                }
                StickyBottomSaveButton(title: "Save Log", tint: AppTheme.accent) {
                    saveVomitingLog()
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    ModalToolbarTitle(icon: option.icon, title: option.title, tint: option.tint)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 10) {
                        Button(localizedAppString("Save Progress")) {
                            saveProgress()
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)

                        ToolbarCloseButton {
                            dismiss()
                        }
                    }
                }
            }
        }
        .presentationDetents([.large])
        .onAppear {
            loadBackgroundIfNeeded()
            loadProgressIfNeeded()
            loadPatternsIfNeeded()
        }
    }

    private var backgroundPage: some View {
        VStack(spacing: 0) {
            ScrollView {
                backgroundForm
                    .padding(18)
            }

            StickyBottomSaveButton(title: "Save", tint: option.tint) {
                saveBackground()
                dismiss()
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var vomitingPatternPage: some View {
        VStack(spacing: 0) {
            ScrollView {
                patternsForm
                    .padding(18)
            }

            StickyBottomSaveButton(title: "Save", tint: option.tint) {
                savePatterns()
                dismiss()
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isQualityOfLifeAssessmentPresented) {
            CyclicVomitingQualityOfLifeAssessmentSheet(
                ageRange: qualityOfLifeAgeGroup,
                tint: option.tint,
                savedResponses: qualityOfLifeResponses
            ) { responses in
                qualityOfLifeResponses = responses
                savePatterns(message: "Quality of life assessment saved.")
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .alert(localizedAppString("About PedsQL"), isPresented: $isQualityOfLifeInfoPresented) {
            Button(localizedAppString("OK"), role: .cancel) {}
        } message: {
            Text(localizedAppString("PedsQL is a pediatric quality-of-life questionnaire. It helps caregivers summarize how often a child has had problems with physical, emotional, social, and school activities during the past month. Scores are for tracking and discussion only, not a medical diagnosis."))
        }
    }

    private var vomitingPatternForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localizedAppString("Vomiting Log Page"))
                .font(.title3.weight(.black))
                .foregroundStyle(AppTheme.text)

            if !progressMessage.isEmpty {
                Text(localizedAppString(progressMessage))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(AppTheme.accent.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            CyclicVomitingFormSection(
                id: "timeTracking",
                title: "Time Tracking",
                icon: "clock",
                tint: option.tint,
                isCollapsed: collapsedFormSections.contains("timeTracking"),
                onToggle: { toggleFormSection("timeTracking") }
            ) {
                CyclicVomitingTimeField(
                    title: "Vomiting Start Time:",
                    selection: $startTime,
                    tint: option.tint
                )

                CyclicVomitingTimeField(
                    title: "Vomiting End Time:",
                    selection: $endTime,
                    tint: option.tint
                )

                CyclicVomitingYesNoPicker(
                    title: "Hospitalization Status",
                    isYes: $hospitalized,
                    tint: option.tint
                )
            }

            CyclicVomitingFormSection(
                id: "prodrome",
                title: "Pre-Episode (Prodrome)",
                icon: "exclamationmark.triangle.fill",
                tint: option.tint,
                isCollapsed: collapsedFormSections.contains("prodrome"),
                onToggle: { toggleFormSection("prodrome") }
            ) {
                CyclicVomitingOptionSection(
                    title: "Vomiting Trigger?",
                    options: triggerOptions,
                    selection: $selectedTriggers,
                    tint: option.tint,
                    otherPlaceholder: "Other triggers",
                    otherText: $otherTriggers
                )

                CyclicVomitingOptionSection(
                    title: "Prodrome Symptoms",
                    options: beforeSymptomOptions,
                    selection: $selectedBeforeSymptoms,
                    tint: option.tint,
                    otherPlaceholder: "Other",
                    otherText: $otherBeforeSymptoms
                )
            }

            CyclicVomitingFormSection(
                id: "during",
                title: "During Episode",
                icon: "waveform.path.ecg",
                tint: option.tint,
                isCollapsed: collapsedFormSections.contains("during"),
                onToggle: { toggleFormSection("during") }
            ) {
                CyclicVomitingOptionSection(
                    title: "Symptoms During Vomiting",
                    options: duringSymptomOptions,
                    selection: $selectedDuringSymptoms,
                    tint: option.tint,
                    otherPlaceholder: "Other",
                    otherText: $otherDuringSymptoms
                )

                CyclicVomitingNumberPicker(
                    title: "Vomiting Frequency",
                    value: $vomitingActsPerDay,
                    tint: option.tint
                )
            }

            CyclicVomitingFormSection(
                id: "recovery",
                title: "Post-Episode (Recovery)",
                icon: "moon.zzz.fill",
                tint: option.tint,
                isCollapsed: collapsedFormSections.contains("recovery"),
                onToggle: { toggleFormSection("recovery") }
            ) {
                CyclicVomitingOptionSection(
                    title: "Recovery Symptoms",
                    options: recoverySymptomOptions,
                    selection: $selectedRecoverySymptoms,
                    tint: option.tint,
                    otherPlaceholder: "Other",
                    otherText: $otherRecoverySymptoms
                )
            }

            CyclicVomitingFormSection(
                id: "medication",
                title: "Current Medication",
                icon: "pills.fill",
                tint: option.tint,
                isCollapsed: collapsedFormSections.contains("medication"),
                onToggle: { toggleFormSection("medication") }
            ) {
                CyclicVomitingOptionSection(
                    title: "Current medications in use (Multi-select)",
                    options: episodeMedicationOptions,
                    selection: $selectedMedications,
                    tint: option.tint,
                    otherPlaceholder: "Other",
                    otherText: $otherMedication
                )
            }
        }
    }

    private var backgroundForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localizedAppString("Background"))
                .font(.title3.weight(.black))
                .foregroundStyle(AppTheme.text)

            CyclicVomitingFormSection(
                id: "backgroundFamily",
                title: "Family History",
                icon: "person.3.fill",
                tint: option.tint,
                isCollapsed: collapsedFormSections.contains("backgroundFamily"),
                onToggle: { toggleFormSection("backgroundFamily") }
            ) {
                CyclicVomitingOptionSection(
                    title: "Parents, grandparents, siblings, etc. with following conditions",
                    options: familyHistoryOptions,
                    selection: $selectedFamilyHistory,
                    tint: option.tint,
                    otherPlaceholder: "",
                    otherText: .constant("")
                )
            }

            CyclicVomitingFormSection(
                id: "backgroundSurgical",
                title: "Surgical History",
                icon: "cross.case.fill",
                tint: option.tint,
                isCollapsed: collapsedFormSections.contains("backgroundSurgical"),
                onToggle: { toggleFormSection("backgroundSurgical") }
            ) {
                CyclicVomitingOptionSection(
                    title: "",
                    options: surgicalHistoryOptions,
                    selection: $selectedSurgicalHistory,
                    tint: option.tint,
                    otherPlaceholder: "Other",
                    otherText: $otherSurgery
                )
            }

            CyclicVomitingFormSection(
                id: "backgroundOnset",
                title: "Onset Time of Recurrent Vomiting",
                icon: "calendar.badge.clock",
                tint: option.tint,
                isCollapsed: collapsedFormSections.contains("backgroundOnset"),
                onToggle: { toggleFormSection("backgroundOnset") }
            ) {
                CyclicVomitingYearMonthField(
                    year: $onsetYear,
                    month: $onsetMonth
                )
            }

            CyclicVomitingFormSection(
                id: "backgroundComorbidities",
                title: "Comorbidities",
                icon: "heart.text.square.fill",
                tint: option.tint,
                isCollapsed: collapsedFormSections.contains("backgroundComorbidities"),
                onToggle: { toggleFormSection("backgroundComorbidities") }
            ) {
                CyclicVomitingOptionSection(
                    title: "Other co-existing conditions",
                    titleNote: "Multiple select",
                    options: comorbidityOptions,
                    selection: $selectedComorbidities,
                    tint: option.tint,
                    otherPlaceholder: "",
                    otherText: .constant("")
                )

                if selectedComorbidities.contains("Inborn errors of metabolism") {
                    CyclicVomitingTextField(
                        title: "Inborn errors of metabolism name",
                        placeholder: "Name required",
                        text: $metabolismName
                    )
                }

                CyclicVomitingTextField(
                    title: "Other",
                    placeholder: "Other condition",
                    text: $otherComorbidity
                )
            }

            CyclicVomitingFormSection(
                id: "backgroundHospital",
                title: "Hospitalization History",
                icon: "building.2.fill",
                tint: option.tint,
                isCollapsed: collapsedFormSections.contains("backgroundHospital"),
                onToggle: { toggleFormSection("backgroundHospital") }
            ) {
                CyclicVomitingYesNoPicker(
                    title: "Have you ever been hospitalized at Beijing Tsinghua Changgung Hospital?",
                    isYes: $hospitalizedAtBeijingHospital,
                    tint: option.tint
                )

                if hospitalizedAtBeijingHospital == true {
                    CyclicVomitingOptionSection(
                        title: "Current medications in use (Multi-select)",
                        options: medicationOptions,
                        selection: $selectedCurrentBackgroundMedications,
                        tint: option.tint,
                        otherPlaceholder: "Other",
                        otherText: $otherCurrentBackgroundMedication
                    )

                    if hasSelectedBackgroundMedication {
                        CyclicVomitingYesNoPicker(
                            title: "Adverse drug reactions",
                            isYes: $hadAdverseDrugReaction,
                            tint: option.tint
                        )

                        if hadAdverseDrugReaction == true {
                            CyclicVomitingTextField(
                                title: "Adverse drug reaction details",
                                placeholder: "Please fill in the specific details",
                                text: $adverseDrugReactionDetails,
                                lineLimit: 2...5
                            )
                        }
                    }
                } else if hospitalizedAtBeijingHospital == false {
                    CyclicVomitingOptionSection(
                        title: "Which of the following medications have been used in the past? (Multi-select)",
                        options: pastMedicationOptions,
                        selection: $selectedPastMedications,
                        tint: option.tint,
                        otherPlaceholder: "Other",
                        otherText: $otherPastMedication
                    )
                }
            }
        }
    }

    private var patternsForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localizedAppString("Baseline Vomiting Patterns & Quality of Life"))
                .font(.title3.weight(.black))
                .foregroundStyle(AppTheme.text)

            if !patternsMessage.isEmpty {
                Text(localizedAppString(patternsMessage))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(AppTheme.accent.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            CyclicVomitingFormSection(
                id: "patternsEpisode",
                title: "Episode Pattern",
                icon: "calendar.badge.clock",
                tint: option.tint,
                isCollapsed: collapsedFormSections.contains("patternsEpisode"),
                onToggle: { toggleFormSection("patternsEpisode") }
            ) {
                CyclicVomitingSingleChoiceSection(
                    title: "Number of vomiting episodes in the past year",
                    options: episodesPastYearOptions,
                    selection: $episodesPastYear,
                    tint: option.tint
                )

                CyclicVomitingSingleChoiceSection(
                    title: "Interval between vomiting episodes",
                    options: episodeIntervalOptions,
                    selection: $episodeInterval,
                    tint: option.tint
                )

                CyclicVomitingSingleChoiceSection(
                    title: "Duration of each vomiting episode",
                    options: episodeDurationOptions,
                    selection: $episodeDuration,
                    tint: option.tint
                )
            }

            CyclicVomitingFormSection(
                id: "patternsTriggers",
                title: "Historical Triggers",
                icon: "bolt.heart.fill",
                tint: option.tint,
                isCollapsed: collapsedFormSections.contains("patternsTriggers"),
                onToggle: { toggleFormSection("patternsTriggers") }
            ) {
                CyclicVomitingOptionSection(
                    title: "Historical triggers before each vomiting episode",
                    options: triggerOptions,
                    selection: $selectedHistoricalTriggers,
                    tint: option.tint,
                    otherPlaceholder: "Other triggers",
                    otherText: $otherHistoricalTriggers
                )
            }

            CyclicVomitingFormSection(
                id: "patternsProdrome",
                title: "Prodromal Symptoms",
                icon: "exclamationmark.triangle.fill",
                tint: option.tint,
                isCollapsed: collapsedFormSections.contains("patternsProdrome"),
                onToggle: { toggleFormSection("patternsProdrome") }
            ) {
                CyclicVomitingOptionSection(
                    title: "Symptoms before each vomiting episode starts (Multi-select)",
                    options: baselineProdromalSymptomOptions,
                    selection: $selectedProdromalSymptoms,
                    tint: option.tint,
                    otherPlaceholder: "Other",
                    otherText: $otherProdromalSymptoms
                )
            }

            CyclicVomitingFormSection(
                id: "patternsDuring",
                title: "Symptoms During Episodes",
                icon: "waveform.path.ecg",
                tint: option.tint,
                isCollapsed: collapsedFormSections.contains("patternsDuring"),
                onToggle: { toggleFormSection("patternsDuring") }
            ) {
                CyclicVomitingOptionSection(
                    title: "Symptoms during each vomiting episode (Multi-select)",
                    options: baselineDuringSymptomOptions,
                    selection: $selectedEpisodeSymptoms,
                    tint: option.tint,
                    otherPlaceholder: "Other",
                    otherText: $otherEpisodeSymptoms
                )
            }

            CyclicVomitingFormSection(
                id: "patternsPostdrome",
                title: "Postdromal Symptoms",
                icon: "moon.zzz.fill",
                tint: option.tint,
                isCollapsed: collapsedFormSections.contains("patternsPostdrome"),
                onToggle: { toggleFormSection("patternsPostdrome") }
            ) {
                CyclicVomitingOptionSection(
                    title: "Symptoms from the time vomiting stops until full recovery (Multi-select)",
                    options: recoverySymptomOptions,
                    selection: $selectedPostdromalSymptoms,
                    tint: option.tint,
                    otherPlaceholder: "Other",
                    otherText: $otherPostdromalSymptoms
                )
            }

            CyclicVomitingFormSection(
                id: "patternsGrowth",
                title: "Growth",
                icon: "ruler.fill",
                tint: option.tint,
                isCollapsed: collapsedFormSections.contains("patternsGrowth"),
                onToggle: { toggleFormSection("patternsGrowth") }
            ) {
                HStack(spacing: 10) {
                    CyclicVomitingMeasurementField(
                        title: "Current Height of the child",
                        units: ["cm", "in"],
                        text: $childHeightCm,
                        selectedUnit: $childHeightUnit
                    )

                    CyclicVomitingMeasurementField(
                        title: "Current Weight of the child",
                        units: ["Kg", "lbs"],
                        text: $childWeightKg,
                        selectedUnit: $childWeightUnit
                    )
                }
            }

            CyclicVomitingFormSection(
                id: "patternsQuality",
                title: "Current Quality of Life Status",
                icon: "heart.text.square.fill",
                tint: option.tint,
                isCollapsed: collapsedFormSections.contains("patternsQuality"),
                onToggle: { toggleFormSection("patternsQuality") }
            ) {
                CyclicVomitingSingleChoiceSection(
                    title: "Choose age range",
                    options: qualityOfLifeAgeOptions,
                    selection: $qualityOfLifeAgeGroup,
                    tint: option.tint
                )
                .onChange(of: qualityOfLifeAgeGroup) { oldValue, newValue in
                    if oldValue != newValue {
                        qualityOfLifeResponses = [:]
                    }
                }

                if isQualityOfLifeAssessmentAvailable {
                    HStack(spacing: 8) {
                        Button {
                            isQualityOfLifeAssessmentPresented = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "heart.text.square.fill")
                                    .font(.subheadline.weight(.bold))

                                Text(localizedAppString(qualityOfLifeResponses.isEmpty ? "Assess Quality of Life Here" : "Edit Quality of Life Assessment"))
                                    .font(.subheadline.weight(.bold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.72)

                                Spacer(minLength: 6)

                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.black))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 11)
                            .foregroundStyle(.white)
                            .background(option.tint)
                            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                        }
                        .buttonStyle(.plain)

                        Button {
                            isQualityOfLifeInfoPresented = true
                        } label: {
                            Image(systemName: "info.circle.fill")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(option.tint)
                                .frame(width: 44, height: 44)
                                .background(option.tint.opacity(0.12))
                                .clipShape(Circle())
                                .accessibilityLabel(localizedAppString("About PedsQL"))
                        }
                        .buttonStyle(.plain)
                    }
                }

                if let qualityOfLifeScoreSummary {
                    HStack(spacing: 8) {
                        qualityOfLifeSummaryPill(title: "Total Score", value: qualityOfLifeScoreSummary.total)
                        qualityOfLifeSummaryPill(title: "Physical Health", value: qualityOfLifeScoreSummary.physical)
                        qualityOfLifeSummaryPill(title: "Psychosocial", value: qualityOfLifeScoreSummary.psychosocial)
                    }
                    .padding(10)
                    .background(option.tint.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }

    private func qualityOfLifeSummaryPill(title: String, value: String) -> some View {
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
        .background(.white.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
    }

    private func saveVomitingLog() {
        let comments = [
            line(title: "Vomiting Start Time:", value: localizedDateString(startTime, dateStyle: .medium, timeStyle: .short)),
            line(title: "Vomiting End Time:", value: localizedDateString(endTime, dateStyle: .medium, timeStyle: .short)),
            line(title: "Hospitalized for this episode?", value: yesNoText(hospitalized)),
            line(title: "Triggers before this vomiting episode", value: selectedValues(selectedTriggers, otherText: otherTriggers)),
            line(title: "Symptoms before this vomiting episode started", value: selectedValues(selectedBeforeSymptoms, otherText: otherBeforeSymptoms)),
            line(title: "Symptoms during this vomiting episode", value: selectedValues(selectedDuringSymptoms, otherText: otherDuringSymptoms)),
            line(title: "Symptoms from vomiting stopped until full recovery", value: selectedValues(selectedRecoverySymptoms, otherText: otherRecoverySymptoms)),
            line(title: "Number of vomiting acts per day", value: "\(vomitingActsPerDay)"),
            line(title: "Current medications in use", value: selectedValues(selectedMedications, otherText: otherMedication))
        ]
        .joined(separator: "\n")

        let entry = HealthLogEntry(
            id: UUID(),
            type: .quickLog,
            categoryID: option.id,
            title: option.title,
            timestamp: startTime,
            severity: hospitalized == true ? 5 : min(max(vomitingActsPerDay, 1), 5),
            value: "\(vomitingActsPerDay) \(localizedAppString(vomitingActsPerDay == 1 ? "vomiting act/day" : "vomiting acts/day"))",
            comments: comments
        )

        onSave(entry)
        clearProgress()
        dismiss()
    }

    private func line(title: String, value: String) -> String {
        "\(localizedAppString(title)): \(value)"
    }

    private func yesNoText(_ value: Bool?) -> String {
        guard let value else { return localizedAppString("Not selected") }
        return localizedAppString(value ? "Yes" : "No")
    }

    private var hasSelectedBackgroundMedication: Bool {
        selectedCurrentBackgroundMedications.contains { !$0.hasPrefix("None") }
            || !otherCurrentBackgroundMedication.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func saveProgress() {
        let data = CyclicVomitingProgressData(
            startTime: startTime,
            endTime: endTime,
            hospitalized: hospitalized,
            triggers: selectedTriggers.sorted(),
            otherTriggers: otherTriggers.trimmingCharacters(in: .whitespacesAndNewlines),
            beforeSymptoms: selectedBeforeSymptoms.sorted(),
            otherBeforeSymptoms: otherBeforeSymptoms.trimmingCharacters(in: .whitespacesAndNewlines),
            duringSymptoms: selectedDuringSymptoms.sorted(),
            otherDuringSymptoms: otherDuringSymptoms.trimmingCharacters(in: .whitespacesAndNewlines),
            recoverySymptoms: selectedRecoverySymptoms.sorted(),
            otherRecoverySymptoms: otherRecoverySymptoms.trimmingCharacters(in: .whitespacesAndNewlines),
            vomitingActsPerDay: vomitingActsPerDay,
            medications: selectedMedications.sorted(),
            otherMedication: otherMedication.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        if let encoded = try? JSONEncoder().encode(data) {
            progressData = encoded
            progressMessage = "Progress saved."
        }
    }

    private func loadProgressIfNeeded() {
        guard !didLoadProgress else { return }
        didLoadProgress = true
        guard !progressData.isEmpty,
              let data = try? JSONDecoder().decode(CyclicVomitingProgressData.self, from: progressData) else {
            return
        }

        startTime = data.startTime
        endTime = data.endTime
        hospitalized = data.hospitalized
        selectedTriggers = Set(data.triggers)
        otherTriggers = data.otherTriggers
        selectedBeforeSymptoms = Set(data.beforeSymptoms)
        otherBeforeSymptoms = data.otherBeforeSymptoms
        selectedDuringSymptoms = Set(data.duringSymptoms)
        otherDuringSymptoms = data.otherDuringSymptoms
        selectedRecoverySymptoms = Set(data.recoverySymptoms)
        otherRecoverySymptoms = data.otherRecoverySymptoms
        vomitingActsPerDay = max(1, data.vomitingActsPerDay)
        selectedMedications = Set(data.medications)
        otherMedication = data.otherMedication
    }

    private func loadPatternsIfNeeded() {
        guard !didLoadPatterns else { return }
        didLoadPatterns = true
        guard !patternsData.isEmpty,
              let data = try? JSONDecoder().decode(CyclicVomitingPatternsData.self, from: patternsData) else {
            return
        }

        episodesPastYear = data.episodesPastYear
        episodeInterval = data.episodeInterval
        episodeDuration = data.episodeDuration
        selectedHistoricalTriggers = Set(data.historicalTriggers)
        otherHistoricalTriggers = data.otherHistoricalTriggers
        selectedProdromalSymptoms = Set(data.prodromalSymptoms)
        otherProdromalSymptoms = data.otherProdromalSymptoms
        selectedEpisodeSymptoms = Set(data.episodeSymptoms)
        otherEpisodeSymptoms = data.otherEpisodeSymptoms
        selectedPostdromalSymptoms = Set(data.postdromalSymptoms)
        otherPostdromalSymptoms = data.otherPostdromalSymptoms
        childHeightCm = data.heightCm
        childHeightUnit = data.heightUnit ?? "cm"
        childWeightKg = data.weightKg
        childWeightUnit = data.weightUnit ?? "Kg"
        qualityOfLifeAgeGroup = data.qualityOfLifeAgeGroup
        qualityOfLifeResponses = data.qualityOfLifeResponses
    }

    private func clearProgress() {
        progressData = Data()
        progressMessage = ""
    }

    private func loadBackgroundIfNeeded() {
        guard !didLoadBackground else { return }
        didLoadBackground = true
        guard !backgroundData.isEmpty,
              let data = try? JSONDecoder().decode(CyclicVomitingBackgroundData.self, from: backgroundData) else {
            return
        }

        selectedFamilyHistory = Set(data.familyHistory)
        selectedSurgicalHistory = Set(data.surgicalHistory)
        otherSurgery = data.otherSurgery
        onsetYear = data.onsetYear
        onsetMonth = data.onsetMonth
        selectedComorbidities = Set(data.comorbidities)
        metabolismName = data.metabolismName
        otherComorbidity = data.otherComorbidity
        hospitalizedAtBeijingHospital = data.hospitalizedAtBeijingHospital
        selectedCurrentBackgroundMedications = Set(data.currentMedications)
        otherCurrentBackgroundMedication = data.otherCurrentMedication
        hadAdverseDrugReaction = data.hadAdverseDrugReaction
        adverseDrugReactionDetails = data.adverseDrugReactionDetails
        selectedPastMedications = Set(data.pastMedications)
        otherPastMedication = data.otherPastMedication
    }

    private func saveBackground() {
        let savedCurrentMedications = hospitalizedAtBeijingHospital == true ? selectedCurrentBackgroundMedications.sorted() : []
        let savedOtherCurrentMedication = hospitalizedAtBeijingHospital == true ? otherCurrentBackgroundMedication.trimmingCharacters(in: .whitespacesAndNewlines) : ""
        let savedPastMedications = hospitalizedAtBeijingHospital == false ? selectedPastMedications.sorted() : []
        let savedOtherPastMedication = hospitalizedAtBeijingHospital == false ? otherPastMedication.trimmingCharacters(in: .whitespacesAndNewlines) : ""
        let savedHadAdverseReaction = hospitalizedAtBeijingHospital == true && hasSelectedBackgroundMedication && hadAdverseDrugReaction == true

        let data = CyclicVomitingBackgroundData(
            familyHistory: selectedFamilyHistory.sorted(),
            surgicalHistory: selectedSurgicalHistory.sorted(),
            otherSurgery: otherSurgery.trimmingCharacters(in: .whitespacesAndNewlines),
            onsetYear: onsetYear.trimmingCharacters(in: .whitespacesAndNewlines),
            onsetMonth: onsetMonth.trimmingCharacters(in: .whitespacesAndNewlines),
            comorbidities: selectedComorbidities.sorted(),
            metabolismName: metabolismName.trimmingCharacters(in: .whitespacesAndNewlines),
            otherComorbidity: otherComorbidity.trimmingCharacters(in: .whitespacesAndNewlines),
            hospitalizedAtBeijingHospital: hospitalizedAtBeijingHospital,
            currentMedications: savedCurrentMedications,
            otherCurrentMedication: savedOtherCurrentMedication,
            hadAdverseDrugReaction: savedHadAdverseReaction,
            adverseDrugReactionDetails: savedHadAdverseReaction ? adverseDrugReactionDetails.trimmingCharacters(in: .whitespacesAndNewlines) : "",
            pastMedications: savedPastMedications,
            otherPastMedication: savedOtherPastMedication
        )

        if let encoded = try? JSONEncoder().encode(data) {
            backgroundData = encoded
        }
    }

    private func savePatterns(message: String = "Patterns saved.") {
        let data = CyclicVomitingPatternsData(
            episodesPastYear: episodesPastYear,
            episodeInterval: episodeInterval,
            episodeDuration: episodeDuration,
            historicalTriggers: selectedHistoricalTriggers.sorted(),
            otherHistoricalTriggers: otherHistoricalTriggers.trimmingCharacters(in: .whitespacesAndNewlines),
            prodromalSymptoms: selectedProdromalSymptoms.sorted(),
            otherProdromalSymptoms: otherProdromalSymptoms.trimmingCharacters(in: .whitespacesAndNewlines),
            episodeSymptoms: selectedEpisodeSymptoms.sorted(),
            otherEpisodeSymptoms: otherEpisodeSymptoms.trimmingCharacters(in: .whitespacesAndNewlines),
            postdromalSymptoms: selectedPostdromalSymptoms.sorted(),
            otherPostdromalSymptoms: otherPostdromalSymptoms.trimmingCharacters(in: .whitespacesAndNewlines),
            heightCm: childHeightCm.trimmingCharacters(in: .whitespacesAndNewlines),
            heightUnit: childHeightUnit,
            weightKg: childWeightKg.trimmingCharacters(in: .whitespacesAndNewlines),
            weightUnit: childWeightUnit,
            qualityOfLifeAgeGroup: qualityOfLifeAgeGroup,
            qualityOfLifeResponses: qualityOfLifeResponses
        )

        if let encoded = try? JSONEncoder().encode(data) {
            patternsData = encoded
            patternsMessage = message
        }
    }

    private func toggleFormSection(_ id: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if collapsedFormSections.contains(id) {
                collapsedFormSections.remove(id)
            } else {
                collapsedFormSections.insert(id)
            }
        }
    }

    private func selectedValues(_ values: Set<String>, otherText: String) -> String {
        var labels = values.sorted().map { localizedAppString($0) }
        let trimmed = otherText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            labels.append(trimmed)
        }
        return labels.isEmpty ? localizedAppString("None") : labels.joined(separator: ", ")
    }
}

