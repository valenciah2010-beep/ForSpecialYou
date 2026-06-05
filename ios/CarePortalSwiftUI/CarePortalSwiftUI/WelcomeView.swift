import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers

struct WelcomeView: View {
    let user: CarePortalUser
    let logout: () -> Void

    var body: some View {
        TabView {
            BasicHealthView(user: user)
                .tabItem {
                    Label("Health", systemImage: "heart.text.square")
                }

            TherapyTrackingView()
                .tabItem {
                    Label("Therapy", systemImage: "figure.mind.and.body")
                }

            NutrientView(user: user)
                .tabItem {
                    Label("Nutrient", systemImage: "leaf")
                }

            CommunityView()
                .tabItem {
                    Label("Community", systemImage: "person.3")
                }

            ProfileView(user: user, logout: logout)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
        .tint(AppTheme.accent)
    }
}

struct BasicHealthView: View {
    let user: CarePortalUser
    @AppStorage private var childName: String
    @AppStorage private var birthDate: String
    @AppStorage private var supportNeeds: String
    @AppStorage private var homeSchoolNotes: String
    @AppStorage private var emergencyContact: String
    @AppStorage private var careNotes: String
    @AppStorage private var profileImageData: Data
    @AppStorage private var quickLogSelection: String
    @AppStorage private var healthLogData: Data
    @AppStorage private var medicationData: Data
    @AppStorage private var medicationCheckData: Data
    @State private var isQuickLogEditorPresented = false
    @State private var activeLogInput: HealthLogInputTarget?
    @State private var activeSeizureTimer: QuickLogOption?
    @State private var activePainLog: QuickLogOption?
    @State private var activeMedicineLog: QuickLogOption?
    @State private var activeSleepSnapshot: SleepSnapshotEditorTarget?
    @State private var draggingQuickLogID: String?

    init(user: CarePortalUser) {
        self.user = user
        self._childName = AppStorage(wrappedValue: "", "profile.\(user.id).fullName")
        self._birthDate = AppStorage(wrappedValue: "", "profile.\(user.id).birthDate")
        self._supportNeeds = AppStorage(wrappedValue: "", "profile.\(user.id).phone")
        self._homeSchoolNotes = AppStorage(wrappedValue: "", "profile.\(user.id).address")
        self._emergencyContact = AppStorage(wrappedValue: "", "profile.\(user.id).emergencyContact")
        self._careNotes = AppStorage(wrappedValue: "", "profile.\(user.id).medicalNotes")
        self._profileImageData = AppStorage(wrappedValue: Data(), "profile.\(user.id).profileImageData")
        self._quickLogSelection = AppStorage(
            wrappedValue: QuickLogOption.defaultSelectionString,
            "health.\(user.id).quickLogSelection"
        )
        self._healthLogData = AppStorage(wrappedValue: Data(), "health.\(user.id).logData")
        self._medicationData = AppStorage(wrappedValue: Data(), "health.\(user.id).medicationData")
        self._medicationCheckData = AppStorage(wrappedValue: Data(), "health.\(user.id).medicationCheckData")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HealthDashboardHeader(
                        childName: displayChildName,
                        parentName: user.nickname,
                        imageData: profileImageData
                    )

                    HStack {
                        DashboardSectionTitle("Quick-log buttons")

                        NavigationLink {
                            QuickLogTrendsView(options: selectedQuickLogs, entries: logEntries)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 28, height: 28)
                                    .background(AppTheme.accent)
                                    .clipShape(Circle())

                                Text("History")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(AppTheme.accent)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Open quick-log history")

                        Spacer()

                        Button {
                            isQuickLogEditorPresented = true
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(AppTheme.accent)
                                .frame(width: 34, height: 34)
                                .background(AppTheme.panel)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
                        }
                        .accessibilityLabel("Choose quick-log buttons")
                    }

                    LazyVGrid(columns: quickLogColumns, spacing: 10) {
                        ForEach(selectedQuickLogs) { option in
                            QuickLogCard(option: option) {
                                if option.id == "seizure" {
                                    activeSeizureTimer = option
                                } else if option.id == "pain" {
                                    activePainLog = option
                                } else if option.id == "medsFood" {
                                    activeMedicineLog = option
                                } else {
                                    activeLogInput = .quickLog(option)
                                }
                            }
                            .opacity(draggingQuickLogID == option.id ? 0.55 : 1)
                            .onDrag {
                                draggingQuickLogID = option.id
                                return NSItemProvider(object: option.id as NSString)
                            }
                            .onDrop(
                                of: [UTType.text],
                                delegate: QuickLogDropDelegate(
                                    targetOption: option,
                                    selectedOptions: selectedQuickLogs,
                                    draggingQuickLogID: $draggingQuickLogID,
                                    moveAction: moveQuickLog
                                )
                            )
                        }
                    }

                    HStack {
                        DashboardSectionTitle("Daily Snapshot")

                        NavigationLink {
                            SnapshotHistoryView(options: SnapshotOption.all, entries: logEntries)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 28, height: 28)
                                    .background(AppTheme.accent)
                                    .clipShape(Circle())

                                Text("History")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(AppTheme.accent)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Open daily snapshot history")

                        Spacer()
                    }

                    LazyVGrid(columns: snapshotColumns, spacing: 10) {
                        ForEach(SnapshotOption.all) { option in
                            let sleepSummary = option.id == "sleep" ? latestSleepSummary : nil

                            SnapshotCard(
                                option: option,
                                displayValue: sleepSummary?.durationText,
                                displayDetail: sleepSummary?.detailText,
                                sleepDurationText: sleepSummary?.durationText
                            ) {
                                if option.id == "sleep" {
                                    activeSleepSnapshot = SleepSnapshotEditorTarget(
                                        option: option,
                                        existingEntry: todaysSleepEntry
                                    )
                                } else {
                                    activeLogInput = .snapshot(option)
                                }
                            }
                        }
                    }

                    DashboardSectionTitle("Insights & Alerts")

                    VStack(spacing: 10) {
                        InsightCard(
                            title: "Tip",
                            message: "\(displayChildName)'s sleep was a little lower than goal. Watch energy and regulation today."
                        )
                        InsightCard(
                            title: "Notice",
                            message: "Log digestion and meals after school to keep the daily snapshot complete."
                        )
                        InsightCard(
                            title: "Reminder",
                            message: "Update care notes after therapy if any new support strategies helped."
                        )
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Dashboard")
            .sheet(isPresented: $isQuickLogEditorPresented) {
                QuickLogSelectionSheet(selectedIDs: selectedQuickLogIDsBinding)
            }
            .sheet(item: $activeLogInput) { target in
                HealthLogEntrySheet(target: target) { entry in
                    saveLogEntry(entry)
                }
            }
            .sheet(item: $activeSleepSnapshot) { option in
                SleepRestSnapshotSheet(target: option) { entry in
                    saveSleepEntry(entry)
                }
            }
            .sheet(item: $activeSeizureTimer) { option in
                SeizureTimerSheet(option: option, initialSeizureType: mostRecentSeizureType) { entry in
                    saveLogEntry(entry)
                }
            }
            .sheet(item: $activePainLog) { option in
                PainLogEntrySheet(option: option) { entry in
                    saveLogEntry(entry)
                }
            }
            .sheet(item: $activeMedicineLog) { option in
                MedicineLogSheet(
                    option: option,
                    medications: medicationsBinding,
                    medicationCheckState: medicationCheckStateBinding
                ) { entry in
                    saveLogEntry(entry)
                }
            }
            .onAppear {
                syncParentAppData()
            }
        }
    }

    private var quickLogColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ]
    }

    private var snapshotColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ]
    }

    private var displayChildName: String {
        let trimmed = childName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Child profile" : trimmed
    }

    private var selectedQuickLogs: [QuickLogOption] {
        orderedSelectedQuickLogIDs.compactMap { QuickLogOption.option(id: $0) }
    }

    private var selectedQuickLogIDs: Set<String> {
        Set(orderedSelectedQuickLogIDs)
    }

    private var orderedSelectedQuickLogIDs: [String] {
        let storedIDs = quickLogSelection.split(separator: ",").map(String.init)
        let knownIDs = Set(QuickLogOption.all.map(\.id))
        let orderedKnownIDs = storedIDs.filter { knownIDs.contains($0) }
        return orderedKnownIDs.isEmpty ? QuickLogOption.defaultSelectionIDs : orderedKnownIDs
    }

    private var selectedQuickLogIDsBinding: Binding<Set<String>> {
        Binding {
            selectedQuickLogIDs
        } set: { newValue in
            let keptCurrentOrder = orderedSelectedQuickLogIDs.filter { newValue.contains($0) }
            let newlyAdded = QuickLogOption.all
                .map(\.id)
                .filter { newValue.contains($0) && !keptCurrentOrder.contains($0) }

            quickLogSelection = (keptCurrentOrder + newlyAdded)
                .joined(separator: ",")
        }
    }

    private var logEntries: [HealthLogEntry] {
        guard !healthLogData.isEmpty else { return [] }
        return (try? JSONDecoder().decode([HealthLogEntry].self, from: healthLogData)) ?? []
    }

    private var medications: [MedicationSchedule] {
        guard !medicationData.isEmpty else { return [] }
        return (try? JSONDecoder().decode([MedicationSchedule].self, from: medicationData)) ?? []
    }

    private var medicationsBinding: Binding<[MedicationSchedule]> {
        Binding {
            medications
        } set: { newMedications in
            saveMedications(newMedications)
        }
    }

    private var medicationCheckState: MedicationCheckState {
        guard !medicationCheckData.isEmpty,
              let savedState = try? JSONDecoder().decode(MedicationCheckState.self, from: medicationCheckData),
              savedState.dateKey == MedicationCheckState.todayKey else {
            return MedicationCheckState.today()
        }

        return savedState
    }

    private var medicationCheckStateBinding: Binding<MedicationCheckState> {
        Binding {
            medicationCheckState
        } set: { newState in
            saveMedicationCheckState(newState)
        }
    }

    private var childProfileSync: ChildProfileSync {
        ChildProfileSync(
            fullName: childName,
            birthDate: birthDate,
            supportNeeds: supportNeeds,
            homeSchoolNotes: homeSchoolNotes,
            emergencyContact: emergencyContact,
            careNotes: careNotes
        )
    }

    private var latestSleepSummary: SleepSnapshotSummary? {
        guard let entry = logEntries
            .filter({ $0.type == .snapshot && $0.categoryID == "sleep" })
            .sorted(by: { $0.timestamp > $1.timestamp })
            .first else {
            return nil
        }

        let parts = entry.value
            .components(separatedBy: "·")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard let duration = parts.first else {
            return SleepSnapshotSummary(durationText: "Saved", detailText: "Sleep logged")
        }

        let detail = parts.dropFirst().joined(separator: " · ")
        return SleepSnapshotSummary(
            durationText: duration,
            detailText: detail.isEmpty ? "Sleep logged" : detail
        )
    }

    private var todaysSleepEntry: HealthLogEntry? {
        logEntries
            .filter { entry in
                entry.type == .snapshot
                    && entry.categoryID == "sleep"
                    && Calendar.current.isDateInToday(entry.timestamp)
            }
            .sorted { $0.timestamp > $1.timestamp }
            .first
    }

    private var mostRecentSeizureType: String {
        logEntries
            .filter { $0.type == .quickLog && $0.categoryID == "seizure" }
            .sorted { $0.timestamp > $1.timestamp }
            .compactMap { seizureType(from: $0) }
            .first ?? "Seizure Type"
    }

    private func seizureType(from entry: HealthLogEntry) -> String? {
        let parts = entry.value
            .components(separatedBy: "·")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        guard parts.count > 1 else { return nil }

        let type = parts[1]
        guard !type.isEmpty, type != "Seizure Type" else { return nil }
        return type
    }

    private func saveLogEntry(_ entry: HealthLogEntry) {
        var updatedEntries = logEntries
        updatedEntries.append(entry)
        updatedEntries.sort { $0.timestamp < $1.timestamp }

        if let data = try? JSONEncoder().encode(updatedEntries) {
            healthLogData = data
        }

        syncParentAppData(healthLogs: updatedEntries)
    }

    private func saveSleepEntry(_ entry: HealthLogEntry) {
        var updatedEntries = logEntries.filter { savedEntry in
            !(savedEntry.type == .snapshot
              && savedEntry.categoryID == "sleep"
              && Calendar.current.isDate(savedEntry.timestamp, inSameDayAs: entry.timestamp))
        }
        updatedEntries.append(entry)
        updatedEntries.sort { $0.timestamp < $1.timestamp }

        if let data = try? JSONEncoder().encode(updatedEntries) {
            healthLogData = data
        }

        syncParentAppData(healthLogs: updatedEntries)
    }

    private func saveMedications(_ newMedications: [MedicationSchedule]) {
        let sortedMedications = newMedications.sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }

        if let data = try? JSONEncoder().encode(sortedMedications) {
            medicationData = data
        }
    }

    private func saveMedicationCheckState(_ state: MedicationCheckState) {
        if let data = try? JSONEncoder().encode(state) {
            medicationCheckData = data
        }
    }

    private func syncParentAppData(healthLogs: [HealthLogEntry]? = nil) {
        let logsToSync = healthLogs ?? logEntries
        let profileToSync = childProfileSync

        Task {
            try? await AuthAPI().syncAppData(
                userId: user.id,
                childProfile: profileToSync,
                healthLogs: logsToSync
            )
        }
    }

    private func moveQuickLog(_ draggedID: String, _ targetID: String) {
        var orderedIDs = orderedSelectedQuickLogIDs

        guard let fromIndex = orderedIDs.firstIndex(of: draggedID),
              let toIndex = orderedIDs.firstIndex(of: targetID),
              fromIndex != toIndex else {
            return
        }

        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
            let movedID = orderedIDs.remove(at: fromIndex)
            orderedIDs.insert(movedID, at: toIndex)
            quickLogSelection = orderedIDs.joined(separator: ",")
        }
    }
}

struct HealthDashboardHeader: View {
    let childName: String
    let parentName: String
    let imageData: Data

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.75))
                    .frame(width: 52, height: 52)

                if let image = profileImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                } else {
                    Text(initials)
                        .font(.headline.weight(.black))
                        .foregroundStyle(AppTheme.accent)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("\(childName)'s Day")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.text)
                    .lineLimit(1)

                Text("Monitored by \(parentName)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "bell.badge")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.text)
        }
        .padding(14)
        .background(Color(red: 0.82, green: 0.94, blue: 0.94))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var initials: String {
        childName
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map { String($0).uppercased() }
            .joined()
    }

    private var profileImage: UIImage? {
        guard !imageData.isEmpty else { return nil }
        return UIImage(data: imageData)
    }
}

struct DashboardSectionTitle: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.headline.weight(.bold))
            .foregroundStyle(AppTheme.text)
            .padding(.top, 2)
    }
}

struct QuickLogOption: Identifiable {
    let id: String
    let title: String
    let icon: String
    let tint: Color

    static let all: [QuickLogOption] = [
        QuickLogOption(id: "seizure", title: "Seizure Track", icon: "timer", tint: Color(red: 0.94, green: 0.31, blue: 0.29)),
        QuickLogOption(id: "meltdown", title: "Meltdown", icon: "exclamationmark.triangle.fill", tint: Color(red: 0.96, green: 0.74, blue: 0.24)),
        QuickLogOption(id: "stimming", title: "Stimming/Tics", icon: "waveform.path.ecg", tint: Color(red: 0.51, green: 0.69, blue: 0.96)),
        QuickLogOption(id: "bowel", title: "Bowel Movement", icon: "stomach.fill", tint: Color(red: 0.45, green: 0.75, blue: 0.52)),
        QuickLogOption(id: "accident", title: "Accident", icon: "drop.triangle.fill", tint: Color(red: 0.69, green: 0.61, blue: 0.91)),
        QuickLogOption(id: "therapy", title: "Therapy Session", icon: "figure.mind.and.body", tint: Color(red: 0.60, green: 0.78, blue: 0.92)),
        QuickLogOption(id: "deescalation", title: "De-escalation", icon: "hand.raised.fill", tint: Color(red: 0.43, green: 0.77, blue: 0.62)),
        QuickLogOption(id: "allergy", title: "Allergic Reaction", icon: "allergens.fill", tint: Color(red: 0.96, green: 0.58, blue: 0.43)),
        QuickLogOption(id: "pain", title: "Pain", icon: "cross.case.fill", tint: Color(red: 0.92, green: 0.41, blue: 0.47)),
        QuickLogOption(id: "discomfort", title: "Discomfort", icon: "thermometer.medium", tint: Color(red: 0.88, green: 0.72, blue: 0.45)),
        QuickLogOption(id: "medsFood", title: "Medicine", icon: "pills.fill", tint: Color(red: 0.38, green: 0.75, blue: 0.55))
    ]

    static let defaultSelectionString = "seizure,meltdown,medsFood"
    static let defaultSelectionIDs = defaultSelectionString.split(separator: ",").map(String.init)

    static func option(id: String) -> QuickLogOption? {
        all.first { $0.id == id }
    }
}

struct SnapshotOption: Identifiable {
    let id: String
    let title: String
    let icon: String
    let value: String
    let detail: String
    let tint: Color
    let progress: Double

    static let all: [SnapshotOption] = [
        SnapshotOption(
            id: "sleep",
            title: "Sleep & Rest",
            icon: "moon.zzz.fill",
            value: "7h",
            detail: "Tap to log",
            tint: Color(red: 0.34, green: 0.66, blue: 0.88),
            progress: 0.78
        ),
        SnapshotOption(
            id: "digestion",
            title: "Gut & Digestion",
            icon: "stomach.fill",
            value: "1 bowel movement",
            detail: "Normal",
            tint: Color(red: 0.45, green: 0.75, blue: 0.52),
            progress: 0.55
        ),
        SnapshotOption(
            id: "skin",
            title: "Skin",
            icon: "bandage.fill",
            value: "2/5",
            detail: "Eczema check",
            tint: Color(red: 0.89, green: 0.72, blue: 0.49),
            progress: 0.4
        ),
        SnapshotOption(
            id: "nutrition",
            title: "Nutrition",
            icon: "leaf.fill",
            value: "3/4 checks",
            detail: "Supplements",
            tint: Color(red: 0.43, green: 0.77, blue: 0.62),
            progress: 0.75
        )
    ]
}

enum HealthLogInputTarget: Identifiable {
    case quickLog(QuickLogOption)
    case snapshot(SnapshotOption)

    var id: String {
        switch self {
        case .quickLog(let option):
            return "quick-\(option.id)"
        case .snapshot(let option):
            return "snapshot-\(option.id)"
        }
    }

    var title: String {
        switch self {
        case .quickLog(let option):
            return option.title
        case .snapshot(let option):
            return option.title
        }
    }

    var categoryID: String {
        switch self {
        case .quickLog(let option):
            return option.id
        case .snapshot(let option):
            return option.id
        }
    }

    var icon: String {
        switch self {
        case .quickLog(let option):
            return option.icon
        case .snapshot(let option):
            return option.icon
        }
    }

    var tint: Color {
        switch self {
        case .quickLog(let option):
            return option.tint
        case .snapshot(let option):
            return option.tint
        }
    }

    var logType: HealthLogEntry.LogType {
        switch self {
        case .quickLog:
            return .quickLog
        case .snapshot:
            return .snapshot
        }
    }

    var valuePrompt: String {
        switch self {
        case .quickLog:
            return "What happened?"
        case .snapshot:
            return "Snapshot value"
        }
    }
}

struct HealthLogEntry: Identifiable, Codable {
    enum LogType: String, Codable {
        case quickLog
        case snapshot
    }

    let id: UUID
    let type: LogType
    let categoryID: String
    let title: String
    let timestamp: Date
    let severity: Int
    let value: String
    let comments: String
}

struct SleepSnapshotSummary {
    let durationText: String
    let detailText: String
}

struct SleepSnapshotEditorTarget: Identifiable {
    let option: SnapshotOption
    let existingEntry: HealthLogEntry?

    var id: String {
        existingEntry?.id.uuidString ?? "new-\(option.id)"
    }
}

enum MedicationDayTime: String, CaseIterable, Codable, Identifiable {
    case morning
    case noon
    case evening

    var id: String { rawValue }

    var title: String {
        switch self {
        case .morning:
            return "Morning"
        case .noon:
            return "Noon"
        case .evening:
            return "Evening"
        }
    }
}

enum MedicationWeekday: String, CaseIterable, Codable, Identifiable {
    case sunday
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday

    var id: String { rawValue }

    var shortTitle: String {
        switch self {
        case .sunday:
            return "Sun"
        case .monday:
            return "Mon"
        case .tuesday:
            return "Tue"
        case .wednesday:
            return "Wed"
        case .thursday:
            return "Thu"
        case .friday:
            return "Fri"
        case .saturday:
            return "Sat"
        }
    }

    var calendarWeekday: Int {
        switch self {
        case .sunday:
            return 1
        case .monday:
            return 2
        case .tuesday:
            return 3
        case .wednesday:
            return 4
        case .thursday:
            return 5
        case .friday:
            return 6
        case .saturday:
            return 7
        }
    }

    static func today(calendar: Calendar = .current) -> MedicationWeekday {
        let weekday = calendar.component(.weekday, from: Date())
        return allCases.first { $0.calendarWeekday == weekday } ?? .monday
    }
}

enum MedicationScheduleMode: String, CaseIterable, Codable, Identifiable {
    case daily
    case weekly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily:
            return "Times per day"
        case .weekly:
            return "Times per week"
        }
    }
}

struct MedicationSchedule: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var nickname: String
    var mode: MedicationScheduleMode
    var dailyTimes: [MedicationDayTime]
    var weeklyDays: [MedicationWeekday]
    var weeklyTimes: [MedicationDayTime]
    var doses: [String: String]

    static func empty() -> MedicationSchedule {
        MedicationSchedule(
            id: UUID(),
            name: "",
            nickname: "",
            mode: .daily,
            dailyTimes: [],
            weeklyDays: [],
            weeklyTimes: [],
            doses: [:]
        )
    }

    var displayName: String {
        let nicknameText = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let nameText = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return nicknameText.isEmpty ? nameText : nicknameText
    }

    var legalName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func dose(for day: MedicationWeekday?, time: MedicationDayTime) -> String {
        let key = doseKey(day: mode == .weekly ? day : nil, time: time)
        return doses[key, default: ""].trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func doseKey(day: MedicationWeekday?, time: MedicationDayTime) -> String {
        if let day {
            return "\(day.rawValue).\(time.rawValue)"
        }

        return time.rawValue
    }
}

struct MedicationCheckState: Codable, Equatable {
    var dateKey: String
    var checkedIDs: [String]

    static var todayKey: String {
        dateKey(for: Date())
    }

    static func today() -> MedicationCheckState {
        MedicationCheckState(dateKey: todayKey, checkedIDs: [])
    }

    static func dateKey(for date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }
}

struct QuickLogCard: View {
    let option: QuickLogOption
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: 9) {
                Image(systemName: option.icon)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.black.opacity(0.82))
                    .frame(height: 30)

                Text(option.title)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(AppTheme.text)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
                    .frame(height: 28)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 86)
            .padding(.horizontal, 6)
            .background(option.tint.opacity(0.78))
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(.black.opacity(0.08), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

struct QuickLogDropDelegate: DropDelegate {
    let targetOption: QuickLogOption
    let selectedOptions: [QuickLogOption]
    @Binding var draggingQuickLogID: String?
    let moveAction: (String, String) -> Void

    func dropEntered(info: DropInfo) {
        guard let draggingQuickLogID,
              draggingQuickLogID != targetOption.id,
              selectedOptions.contains(where: { $0.id == draggingQuickLogID }) else {
            return
        }

        moveAction(draggingQuickLogID, targetOption.id)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingQuickLogID = nil
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func dropExited(info: DropInfo) {
        if info.location == .zero {
            draggingQuickLogID = nil
        }
    }
}

struct QuickLogSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedIDs: Set<String>

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(QuickLogOption.all) { option in
                        Button {
                            toggle(option)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: selectedIDs.contains(option.id) ? "checkmark.square.fill" : "square")
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(selectedIDs.contains(option.id) ? AppTheme.accent : .secondary)

                                Image(systemName: option.icon)
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(option.tint)
                                    .frame(width: 28)

                                Text(option.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.text)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(14)
                            .background(AppTheme.panel)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .disabled(selectedIDs.count == 1 && selectedIDs.contains(option.id))
                    }
                }
                .padding(18)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Quick Logs")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func toggle(_ option: QuickLogOption) {
        var updatedSelection = selectedIDs

        if selectedIDs.contains(option.id) {
            guard selectedIDs.count > 1 else { return }
            updatedSelection.remove(option.id)
        } else {
            updatedSelection.insert(option.id)
        }

        selectedIDs = updatedSelection
    }
}

struct SnapshotCard: View {
    let option: SnapshotOption
    var displayValue: String?
    var displayDetail: String?
    var sleepDurationText: String?
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Text(option.title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.text)
                    .lineLimit(2)
                    .frame(height: 30, alignment: .topLeading)

                if option.id != "sleep" {
                    HStack {
                        Spacer()
                        Image(systemName: option.icon)
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(option.tint)
                        Spacer()
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(displayValue ?? option.value)
                        .font(option.id == "sleep" ? .title3.weight(.black) : .caption.weight(.bold))
                        .foregroundStyle(AppTheme.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text(displayDetail ?? option.detail)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                if option.id != "sleep" {
                    ProgressView(value: option.progress)
                        .tint(option.tint)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 148)
            .background(option.tint.opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(option.tint.opacity(0.24), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

struct SleepRestSnapshotSheet: View {
    @Environment(\.dismiss) private var dismiss

    let target: SleepSnapshotEditorTarget
    let onSave: (HealthLogEntry) -> Void

    @State private var fellAsleepAt: Date
    @State private var wokeUpAt: Date
    @State private var selectedQuality: SleepRestQuality
    @State private var wakingCount: Int
    @State private var comments: String

    private var option: SnapshotOption {
        target.option
    }

    init(target: SleepSnapshotEditorTarget, onSave: @escaping (HealthLogEntry) -> Void) {
        self.target = target
        self.onSave = onSave

        let prefill = Self.prefill(from: target.existingEntry)
        self._fellAsleepAt = State(initialValue: prefill.fellAsleepAt)
        self._wokeUpAt = State(initialValue: prefill.wokeUpAt)
        self._selectedQuality = State(initialValue: prefill.quality)
        self._wakingCount = State(initialValue: prefill.wakingCount)
        self._comments = State(initialValue: prefill.comments)
    }

    private var sleepDuration: TimeInterval {
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: fellAsleepAt)
        let endComponents = calendar.dateComponents([.hour, .minute], from: wokeUpAt)
        let today = calendar.startOfDay(for: Date())
        let start = calendar.date(
            bySettingHour: startComponents.hour ?? 21,
            minute: startComponents.minute ?? 0,
            second: 0,
            of: today
        ) ?? today
        var end = calendar.date(
            bySettingHour: endComponents.hour ?? 7,
            minute: endComponents.minute ?? 0,
            second: 0,
            of: today
        ) ?? today

        if end <= start {
            end = calendar.date(byAdding: .day, value: 1, to: end) ?? end
        }

        return end.timeIntervalSince(start)
    }

    private var durationText: String {
        let totalMinutes = max(0, Int(sleepDuration / 60))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return minutes == 0 ? "\(hours)h" : "\(hours)h \(minutes)m"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 12) {
                        Text(durationText)
                            .font(.title.weight(.black))
                            .foregroundStyle(AppTheme.text)
                            .frame(width: 82, height: 58)
                            .background(option.tint.opacity(0.18))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Sleep & Rest")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(AppTheme.text)

                            Text("\(durationText) tracked")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Sleep Times")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.text)

                        TimeWheelPicker(title: "Fell asleep at", selection: $fellAsleepAt)
                        TimeWheelPicker(title: "Woke up at", selection: $wokeUpAt)
                    }
                    .authPanel()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Rest Quality")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.text)

                        HStack(spacing: 10) {
                            ForEach(SleepRestQuality.allCases) { quality in
                                Button {
                                    selectedQuality = quality
                                } label: {
                                    VStack(spacing: 6) {
                                        Text(quality.emoji)
                                            .font(.title2)
                                        Text(quality.title)
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(AppTheme.text)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.75)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(selectedQuality == quality ? option.tint.opacity(0.25) : AppTheme.fieldBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(selectedQuality == quality ? option.tint : Color.clear, lineWidth: 2)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .authPanel()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Waking Counter")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.text)

                        HStack(spacing: 14) {
                            Button {
                                wakingCount = max(0, wakingCount - 1)
                            } label: {
                                Image(systemName: "minus")
                                    .font(.headline.weight(.bold))
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.bordered)
                            .tint(option.tint)

                            Text("\(wakingCount)")
                                .font(.title.weight(.black))
                                .foregroundStyle(AppTheme.text)
                                .frame(minWidth: 54)

                            Button {
                                wakingCount += 1
                            } label: {
                                Image(systemName: "plus")
                                    .font(.headline.weight(.bold))
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(option.tint)

                            Text(wakingCount == 1 ? "wake-up" : "wake-ups")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)

                            Spacer()
                        }
                    }
                    .authPanel()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.text)

                        TextField("Nap, bedtime routine, night waking, comfort item, etc.", text: $comments, axis: .vertical)
                            .lineLimit(3...6)
                            .padding(12)
                            .background(AppTheme.fieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .authPanel()
                }
                .padding(18)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Sleep & Rest")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        save()
                    }
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                }
            }
        }
        .presentationDetents([.large])
    }

    private func save() {
        let value = "\(durationText) · \(selectedQuality.title) · \(wakingCount) \(wakingCount == 1 ? "wake-up" : "wake-ups")"
        let timeSummary = "Fell asleep at \(formattedTime(fellAsleepAt))\nWoke up at \(formattedTime(wokeUpAt))"
        let trimmedComments = comments.trimmingCharacters(in: .whitespacesAndNewlines)
        let noteText = trimmedComments.isEmpty ? timeSummary : "\(timeSummary)\n\(trimmedComments)"

        let entry = HealthLogEntry(
            id: target.existingEntry?.id ?? UUID(),
            type: .snapshot,
            categoryID: option.id,
            title: option.title,
            timestamp: target.existingEntry?.timestamp ?? Date(),
            severity: selectedQuality.severity,
            value: value,
            comments: noteText
        )
        onSave(entry)
        dismiss()
    }

    private func formattedTime(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    private static func prefill(from entry: HealthLogEntry?) -> SleepSnapshotPrefill {
        let defaultSleep = defaultTime(hour: 21, minute: 0)
        let defaultWake = defaultTime(hour: 7, minute: 0)

        guard let entry else {
            return SleepSnapshotPrefill(
                fellAsleepAt: defaultSleep,
                wokeUpAt: defaultWake,
                quality: .normal,
                wakingCount: 0,
                comments: ""
            )
        }

        let valueParts = entry.value
            .components(separatedBy: "·")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        let quality = valueParts
            .compactMap { SleepRestQuality(title: $0) }
            .first ?? .normal

        let wakingCount = valueParts
            .compactMap { part -> Int? in
                guard part.localizedCaseInsensitiveContains("wake") else { return nil }
                return Int(part.filter(\.isNumber))
            }
            .first ?? 0

        let lines = entry.comments
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        let fellAsleepAt = lines
            .first { $0.localizedCaseInsensitiveContains("fell asleep at") }
            .flatMap { timeFromLine($0, prefix: "Fell asleep at") } ?? defaultSleep

        let wokeUpAt = lines
            .first { $0.localizedCaseInsensitiveContains("woke up at") }
            .flatMap { timeFromLine($0, prefix: "Woke up at") } ?? defaultWake

        let comments = lines
            .filter {
                !$0.localizedCaseInsensitiveContains("fell asleep at")
                    && !$0.localizedCaseInsensitiveContains("woke up at")
            }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return SleepSnapshotPrefill(
            fellAsleepAt: fellAsleepAt,
            wokeUpAt: wokeUpAt,
            quality: quality,
            wakingCount: wakingCount,
            comments: comments
        )
    }

    private static func defaultTime(hour: Int, minute: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }

    private static func timeFromLine(_ line: String, prefix: String) -> Date? {
        let rawTime = line
            .replacingOccurrences(of: prefix, with: "", options: [.caseInsensitive])
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\u{202F}", with: " ")
            .replacingOccurrences(of: "\u{00A0}", with: " ")

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"

        guard let parsed = formatter.date(from: rawTime) else { return nil }

        let components = Calendar.current.dateComponents([.hour, .minute], from: parsed)
        return Calendar.current.date(
            bySettingHour: components.hour ?? 0,
            minute: components.minute ?? 0,
            second: 0,
            of: Date()
        )
    }
}

private struct SleepSnapshotPrefill {
    let fellAsleepAt: Date
    let wokeUpAt: Date
    let quality: SleepRestQuality
    let wakingCount: Int
    let comments: String
}

struct TimeWheelPicker: View {
    let title: String
    @Binding var selection: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.text)

            DatePicker(title, selection: $selection, displayedComponents: [.hourAndMinute])
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .background(AppTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

enum SleepRestQuality: String, CaseIterable, Identifiable {
    case restless
    case normal
    case deep

    var id: String { rawValue }

    init?(title: String) {
        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let match = Self.allCases.first(where: {
            $0.title.localizedCaseInsensitiveCompare(normalizedTitle) == .orderedSame
        }) else {
            return nil
        }

        self = match
    }

    var title: String {
        switch self {
        case .restless:
            return "Restless"
        case .normal:
            return "Normal"
        case .deep:
            return "Deep"
        }
    }

    var emoji: String {
        switch self {
        case .restless:
            return "😣"
        case .normal:
            return "😴"
        case .deep:
            return "🌙"
        }
    }

    var severity: Int {
        switch self {
        case .restless:
            return 4
        case .normal:
            return 2
        case .deep:
            return 1
        }
    }
}

struct HealthLogEntrySheet: View {
    @Environment(\.dismiss) private var dismiss

    let target: HealthLogInputTarget
    let onSave: (HealthLogEntry) -> Void

    @State private var useCurrentTime = true
    @State private var timestamp = Date()
    @State private var severity = 3.0
    @State private var value = ""
    @State private var comments = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 12) {
                        Image(systemName: target.icon)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(target.tint)
                            .frame(width: 42, height: 42)
                            .background(target.tint.opacity(0.16))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 3) {
                            Text(target.title)
                                .font(.title3.weight(.bold))
                            Text(target.logType == .quickLog ? "Quick log entry" : "Daily snapshot entry")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        Toggle("Use current time", isOn: $useCurrentTime)
                            .font(.subheadline.weight(.semibold))
                            .tint(AppTheme.accent)

                        DatePicker(
                            "Time",
                            selection: $timestamp,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .disabled(useCurrentTime)
                        .opacity(useCurrentTime ? 0.55 : 1)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(target.valuePrompt)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.text)

                            TextField(target.logType == .quickLog ? "Short note" : "Example: 7 hours, normal, 2/5", text: $value)
                                .padding(12)
                                .background(AppTheme.fieldBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Severity: \(Int(severity))/5")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.text)

                            Slider(value: $severity, in: 1...5, step: 1)
                                .tint(target.tint)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Comments")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.text)

                            TextField("Add details, context, triggers, or what helped", text: $comments, axis: .vertical)
                                .lineLimit(4...7)
                                .padding(12)
                                .background(AppTheme.fieldBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                    .authPanel()
                }
                .padding(18)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Add Data")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        save()
                    }
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                }
            }
        }
        .presentationDetents([.large])
        .onAppear {
            value = target.logType == .snapshot ? "" : target.title
        }
    }

    private func save() {
        let entry = HealthLogEntry(
            id: UUID(),
            type: target.logType,
            categoryID: target.categoryID,
            title: target.title,
            timestamp: useCurrentTime ? Date() : timestamp,
            severity: Int(severity),
            value: value.trimmingCharacters(in: .whitespacesAndNewlines),
            comments: comments.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        onSave(entry)
        dismiss()
    }
}

struct MedicineLogSheet: View {
    @Environment(\.dismiss) private var dismiss

    let option: QuickLogOption
    @Binding var medications: [MedicationSchedule]
    @Binding var medicationCheckState: MedicationCheckState
    let onSave: (HealthLogEntry) -> Void

    @State private var checkedMedicationIDs: Set<String> = []
    @State private var editingMedication: MedicationSchedule?

    private var today: MedicationWeekday {
        MedicationWeekday.today()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: option.icon)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(option.tint)
                            .frame(width: 44, height: 44)
                            .background(option.tint.opacity(0.16))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Medicine")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(AppTheme.text)

                            Text(today.shortTitle)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }

                    ForEach(MedicationDayTime.allCases) { time in
                        medicationChecklistSection(for: time)
                    }
                }
                .padding(18)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Medicine")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            editingMedication = MedicationSchedule.empty()
                        } label: {
                            Label("Add New", systemImage: "plus")
                        }

                        if medications.isEmpty {
                            Text("No medicines saved")
                        } else {
                            Section("Edit Existing") {
                                ForEach(medications) { medication in
                                    Button(medication.displayName.isEmpty ? "Unnamed Medicine" : medication.displayName) {
                                        editingMedication = medication
                                    }
                                }
                            }
                        }
                    } label: {
                        Text("Edit")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(AppTheme.accent)
                    }
                }

                ToolbarItem(placement: .bottomBar) {
                    Button {
                        save()
                    } label: {
                        Text("Save Checked Medicine")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppTheme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
        }
        .presentationDetents([.large])
        .onAppear {
            loadSavedCheckedMedicationIDs()
        }
        .sheet(item: $editingMedication) { medication in
            MedicationEditorSheet(medication: medication) { savedMedication in
                upsertMedication(savedMedication)
            }
        }
    }

    private func medicationChecklistSection(for time: MedicationDayTime) -> some View {
        let rows = checklistRows(for: time)

        return VStack(alignment: .leading, spacing: 12) {
            Text(time.title)
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.text)

            if rows.isEmpty {
                Text("None")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(AppTheme.fieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                VStack(spacing: 10) {
                    ForEach(rows) { row in
                        MedicineChecklistRow(
                            row: row,
                            isChecked: checkedMedicationIDs.contains(row.id),
                            tint: option.tint
                        ) {
                            toggleChecked(row.id)
                        }
                    }
                }
            }
        }
        .authPanel()
    }

    private func checklistRows(for time: MedicationDayTime) -> [MedicationChecklistItem] {
        medications.compactMap { medication in
            switch medication.mode {
            case .daily:
                guard medication.dailyTimes.contains(time) else { return nil }
                return MedicationChecklistItem(
                    id: "\(medication.id.uuidString).\(time.rawValue)",
                    medication: medication,
                    time: time,
                    dose: medication.dose(for: nil, time: time)
                )
            case .weekly:
                guard medication.weeklyDays.contains(today), medication.weeklyTimes.contains(time) else { return nil }
                return MedicationChecklistItem(
                    id: "\(medication.id.uuidString).\(today.rawValue).\(time.rawValue)",
                    medication: medication,
                    time: time,
                    dose: medication.dose(for: today, time: time)
                )
            }
        }
    }

    private func toggleChecked(_ id: String) {
        if checkedMedicationIDs.contains(id) {
            checkedMedicationIDs.remove(id)
        } else {
            checkedMedicationIDs.insert(id)
        }
    }

    private func upsertMedication(_ medication: MedicationSchedule) {
        if let index = medications.firstIndex(where: { $0.id == medication.id }) {
            medications[index] = medication
        } else {
            medications.append(medication)
        }

        checkedMedicationIDs.formIntersection(currentChecklistRowIDs)
    }

    private func save() {
        persistCheckedMedicationIDs()

        let allRows = MedicationDayTime.allCases.flatMap { checklistRows(for: $0) }
        let checkedRows = allRows.filter { checkedMedicationIDs.contains($0.id) }
        let checkedSummary = checkedRows.isEmpty
            ? "No medicine checked"
            : checkedRows.map { "\($0.time.title): \($0.medication.displayName)\($0.dose.isEmpty ? "" : " \($0.dose)")" }.joined(separator: "\n")

        let sectionSummary = MedicationDayTime.allCases.map { time in
            let rows = checklistRows(for: time)
            guard !rows.isEmpty else { return "\(time.title): None" }

            let names = rows.map { row in
                let checkedMark = checkedMedicationIDs.contains(row.id) ? "Checked" : "Not checked"
                let doseText = row.dose.isEmpty ? "" : " \(row.dose)"
                return "\(checkedMark) - \(row.medication.displayName)\(doseText)"
            }
            .joined(separator: "; ")

            return "\(time.title): \(names)"
        }
        .joined(separator: "\n")

        let entry = HealthLogEntry(
            id: UUID(),
            type: .quickLog,
            categoryID: option.id,
            title: option.title,
            timestamp: Date(),
            severity: 1,
            value: checkedSummary,
            comments: sectionSummary
        )
        onSave(entry)
        dismiss()
    }

    private var currentChecklistRowIDs: Set<String> {
        Set(MedicationDayTime.allCases.flatMap { time in
            checklistRows(for: time).map(\.id)
        })
    }

    private func loadSavedCheckedMedicationIDs() {
        guard medicationCheckState.dateKey == MedicationCheckState.todayKey else {
            checkedMedicationIDs = []
            return
        }

        checkedMedicationIDs = Set(medicationCheckState.checkedIDs)
            .intersection(currentChecklistRowIDs)
    }

    private func persistCheckedMedicationIDs() {
        let savedIDs = checkedMedicationIDs
            .intersection(currentChecklistRowIDs)
            .sorted()

        medicationCheckState = MedicationCheckState(
            dateKey: MedicationCheckState.todayKey,
            checkedIDs: savedIDs
        )
    }
}

struct MedicationChecklistItem: Identifiable {
    let id: String
    let medication: MedicationSchedule
    let time: MedicationDayTime
    let dose: String
}

struct MedicineChecklistRow: View {
    let row: MedicationChecklistItem
    let isChecked: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isChecked ? tint : .secondary)

                VStack(alignment: .leading, spacing: 3) {
                    Text(row.medication.displayName.isEmpty ? "Unnamed Medicine" : row.medication.displayName)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppTheme.text)

                    if !row.dose.isEmpty {
                        Text(row.dose)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
            .padding(12)
            .background(AppTheme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct MedicationEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: (MedicationSchedule) -> Void

    @State private var draft: MedicationSchedule

    init(medication: MedicationSchedule, onSave: @escaping (MedicationSchedule) -> Void) {
        self.onSave = onSave
        self._draft = State(initialValue: medication)
    }

    private var canSave: Bool {
        let hasName = !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        switch draft.mode {
        case .daily:
            return hasName && !draft.dailyTimes.isEmpty
        case .weekly:
            return hasName && !draft.weeklyDays.isEmpty && !draft.weeklyTimes.isEmpty
        }
    }

    private var doseInputs: [MedicationDoseInput] {
        switch draft.mode {
        case .daily:
            return sortedTimes(draft.dailyTimes).map { time in
                MedicationDoseInput(
                    id: draft.doseKey(day: nil, time: time),
                    label: "\(time.title) dose"
                )
            }
        case .weekly:
            return sortedDays(draft.weeklyDays).flatMap { day in
                sortedTimes(draft.weeklyTimes).map { time in
                    MedicationDoseInput(
                        id: draft.doseKey(day: day, time: time),
                        label: "\(day.shortTitle) \(time.title) dose"
                    )
                }
            }
        }
    }

    private var firstEnteredDose: String? {
        doseInputs
            .compactMap { input in
                let dose = draft.doses[input.id, default: ""].trimmingCharacters(in: .whitespacesAndNewlines)
                return dose.isEmpty ? nil : dose
            }
            .first
    }

    private var canCopyDoseToAll: Bool {
        doseInputs.count > 1 && firstEnteredDose != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Name of medicine", text: $draft.name)
                            .textInputAutocapitalization(.words)
                            .padding(12)
                            .background(AppTheme.fieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        TextField("Preferred nickname", text: $draft.nickname)
                            .textInputAutocapitalization(.words)
                            .padding(12)
                            .background(AppTheme.fieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .authPanel()

                    VStack(alignment: .leading, spacing: 14) {
                        Picker("Schedule", selection: modeBinding) {
                            ForEach(MedicationScheduleMode.allCases) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)

                        if draft.mode == .daily {
                            Text("Times per day")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(AppTheme.text)

                            HStack(spacing: 8) {
                                ForEach(MedicationDayTime.allCases) { time in
                                    MedicationChoicePill(
                                        title: time.title,
                                        isSelected: draft.dailyTimes.contains(time)
                                    ) {
                                        toggleDailyTime(time)
                                    }
                                }
                            }
                        } else {
                            Text("Days of the week")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(AppTheme.text)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                                ForEach(MedicationWeekday.allCases) { day in
                                    MedicationChoicePill(
                                        title: day.shortTitle,
                                        isSelected: draft.weeklyDays.contains(day)
                                    ) {
                                        toggleWeeklyDay(day)
                                    }
                                }
                            }

                            Text("Times per day")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(AppTheme.text)

                            HStack(spacing: 8) {
                                ForEach(MedicationDayTime.allCases) { time in
                                    MedicationChoicePill(
                                        title: time.title,
                                        isSelected: draft.weeklyTimes.contains(time)
                                    ) {
                                        toggleWeeklyTime(time)
                                    }
                                }
                            }
                        }
                    }
                    .authPanel()

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Dose")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.text)

                            Spacer()

                            Button {
                                copyFirstDoseToAll()
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "doc.on.doc")
                                        .font(.caption.weight(.bold))

                                    Text("Same dose")
                                        .font(.caption.weight(.bold))
                                }
                                .foregroundStyle(canCopyDoseToAll ? AppTheme.accent : .secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(AppTheme.fieldBackground)
                                .clipShape(Capsule())
                            }
                            .disabled(!canCopyDoseToAll)
                            .buttonStyle(.plain)
                        }

                        if doseInputs.isEmpty {
                            Text("Choose a time to add doses.")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(doseInputs) { input in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(input.label)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)

                                    TextField("Example: 5 mg, 1 tablet, 2 mL", text: doseBinding(for: input.id))
                                        .padding(12)
                                        .background(AppTheme.fieldBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                            }
                        }
                    }
                    .authPanel()
                }
                .padding(18)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Medicine")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        save()
                    }
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(canSave ? AppTheme.accent : .secondary)
                    .disabled(!canSave)
                }
            }
        }
        .presentationDetents([.large])
    }

    private var modeBinding: Binding<MedicationScheduleMode> {
        Binding {
            draft.mode
        } set: { newMode in
            setScheduleMode(newMode)
        }
    }

    private func doseBinding(for key: String) -> Binding<String> {
        Binding {
            draft.doses[key, default: ""]
        } set: { newValue in
            draft.doses[key] = newValue
        }
    }

    private func setScheduleMode(_ mode: MedicationScheduleMode) {
        guard draft.mode != mode else { return }

        draft.mode = mode

        switch mode {
        case .daily:
            draft.weeklyDays.removeAll()
            draft.weeklyTimes.removeAll()
            draft.doses = draft.doses.filter { !$0.key.contains(".") }
        case .weekly:
            draft.dailyTimes.removeAll()
            draft.doses = draft.doses.filter { $0.key.contains(".") }
        }
    }

    private func copyFirstDoseToAll() {
        guard let dose = firstEnteredDose else { return }

        for input in doseInputs {
            draft.doses[input.id] = dose
        }
    }

    private func toggleDailyTime(_ time: MedicationDayTime) {
        toggle(time, in: &draft.dailyTimes)
    }

    private func toggleWeeklyTime(_ time: MedicationDayTime) {
        toggle(time, in: &draft.weeklyTimes)
    }

    private func toggleWeeklyDay(_ day: MedicationWeekday) {
        toggle(day, in: &draft.weeklyDays)
    }

    private func toggle<T: Equatable>(_ value: T, in values: inout [T]) {
        if let index = values.firstIndex(of: value) {
            values.remove(at: index)
        } else {
            values.append(value)
        }
    }

    private func save() {
        var saved = draft
        saved.name = saved.name.trimmingCharacters(in: .whitespacesAndNewlines)
        saved.nickname = saved.nickname.trimmingCharacters(in: .whitespacesAndNewlines)

        let activeDoseKeys = Set(doseInputs.map(\.id))
        saved.doses = saved.doses.reduce(into: [:]) { result, item in
            let value = item.value.trimmingCharacters(in: .whitespacesAndNewlines)
            if activeDoseKeys.contains(item.key), !value.isEmpty {
                result[item.key] = value
            }
        }

        onSave(saved)
        dismiss()
    }

    private func sortedTimes(_ times: [MedicationDayTime]) -> [MedicationDayTime] {
        MedicationDayTime.allCases.filter { times.contains($0) }
    }

    private func sortedDays(_ days: [MedicationWeekday]) -> [MedicationWeekday] {
        MedicationWeekday.allCases.filter { days.contains($0) }
    }
}

struct MedicationDoseInput: Identifiable {
    let id: String
    let label: String
}

struct MedicationChoicePill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.caption.weight(.bold))

                Text(title)
                    .font(.caption.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .foregroundStyle(isSelected ? .white : AppTheme.text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
            .background(isSelected ? AppTheme.accent : AppTheme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct PainLogEntrySheet: View {
    @Environment(\.dismiss) private var dismiss

    let option: QuickLogOption
    let onSave: (HealthLogEntry) -> Void

    @State private var useCurrentTime = true
    @State private var timestamp = Date()
    @State private var severity = 3.0
    @State private var painPoints: [PainPoint] = []
    @State private var shortComment = ""
    @State private var indicators = ""

    private var displayLocation: String {
        painPoints.isEmpty ? "Tap the body to add a pain dot" : "\(painPoints.count) pain location\(painPoints.count == 1 ? "" : "s")"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 12) {
                        Image(systemName: option.icon)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(option.tint)
                            .frame(width: 42, height: 42)
                            .background(option.tint.opacity(0.16))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Pain")
                                .font(.title3.weight(.bold))
                            Text(displayLocation)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        Toggle("Use current time", isOn: $useCurrentTime)
                            .font(.subheadline.weight(.semibold))
                            .tint(AppTheme.accent)

                        DatePicker(
                            "Time",
                            selection: $timestamp,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .disabled(useCurrentTime)
                        .opacity(useCurrentTime ? 0.55 : 1)

                        PainBodySelector(
                            painPoints: $painPoints,
                            tint: option.tint
                        )

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Severity: \(Int(severity))/5")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.text)

                            Slider(value: $severity, in: 1...5, step: 1)
                                .tint(option.tint)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Short Comment")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.text)

                            TextField("What happened or what helped?", text: $shortComment, axis: .vertical)
                                .lineLimit(3...5)
                                .padding(12)
                                .background(AppTheme.fieldBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Indicators")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.text)

                            TextField("Crying, holding head, aggression, guarding, limping", text: $indicators, axis: .vertical)
                                .lineLimit(3...6)
                                .padding(12)
                                .background(AppTheme.fieldBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                    .authPanel()
                }
                .padding(18)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Pain Log")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        save()
                    }
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                }
            }
        }
        .presentationDetents([.large])
    }

    private func save() {
        let savedLocation = painPoints.isEmpty
            ? "Pain location not selected"
            : painPoints
                .map { "\($0.side.rawValue): \(Int($0.x * 100))%, \(Int($0.y * 100))%" }
                .joined(separator: "; ")
        let notes = [
            shortComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : "Comment: \(shortComment.trimmingCharacters(in: .whitespacesAndNewlines))",
            indicators.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : "Indicators: \(indicators.trimmingCharacters(in: .whitespacesAndNewlines))"
        ]
        .compactMap { $0 }
        .joined(separator: "\n\n")

        let entry = HealthLogEntry(
            id: UUID(),
            type: .quickLog,
            categoryID: option.id,
            title: option.title,
            timestamp: useCurrentTime ? Date() : timestamp,
            severity: Int(severity),
            value: savedLocation,
            comments: notes
        )
        onSave(entry)
        dismiss()
    }
}

enum PainBodySide: String, CaseIterable, Identifiable {
    case front = "Front"
    case back = "Back"

    var id: String { rawValue }
}

struct PainPoint: Identifiable, Equatable {
    let id = UUID()
    let side: PainBodySide
    let x: CGFloat
    let y: CGFloat
}

struct PainBodySelector: View {
    @Binding var painPoints: [PainPoint]
    let tint: Color

    @State private var selectedSide: PainBodySide = .front

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pain Location")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.text)

            VStack(spacing: 10) {
                Picker("Body side", selection: $selectedSide) {
                    ForEach(PainBodySide.allCases) { side in
                        Text(side.rawValue).tag(side)
                    }
                }
                .pickerStyle(.segmented)

                TappablePainBodyMap(
                    side: selectedSide,
                    painPoints: $painPoints,
                    tint: tint
                )
                .frame(height: 430)

                if !painPoints.isEmpty {
                    Button {
                        painPoints.removeAll()
                    } label: {
                        Label("Clear pain dots", systemImage: "xmark.circle")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(AppTheme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Text(painPoints.isEmpty ? "Tap directly on the body to mark pain." : "\(painPoints.count) pain dot\(painPoints.count == 1 ? "" : "s") marked")
                .font(.caption.weight(.bold))
                .foregroundStyle(painPoints.isEmpty ? .secondary : tint)
        }
    }
}

struct TappablePainBodyMap: View {
    let side: PainBodySide
    @Binding var painPoints: [PainPoint]
    let tint: Color

    private var visiblePoints: [PainPoint] {
        painPoints.filter { $0.side == side }
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(side.rawValue)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)

            GeometryReader { proxy in
                ZStack {
                    ImprovedPainBodySilhouette(side: side, tint: tint)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    ForEach(visiblePoints) { point in
                        Circle()
                            .fill(tint)
                            .frame(width: 14, height: 14)
                            .overlay {
                                Circle()
                                    .stroke(.white, lineWidth: 3)
                            }
                            .shadow(color: tint.opacity(0.35), radius: 5, x: 0, y: 2)
                            .position(
                                x: proxy.size.width * point.x,
                                y: proxy.size.height * point.y
                            )
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    SpatialTapGesture()
                        .onEnded { value in
                            let normalizedX = min(max(value.location.x / proxy.size.width, 0), 1)
                            let normalizedY = min(max(value.location.y / proxy.size.height, 0), 1)

                            guard isInsideBody(x: normalizedX, y: normalizedY) else { return }

                            withAnimation(.spring(response: 0.24, dampingFraction: 0.74)) {
                                painPoints.append(PainPoint(side: side, x: normalizedX, y: normalizedY))
                            }
                        }
                )
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(side.rawValue) body pain map")
    }

    private func isInsideBody(x: CGFloat, y: CGFloat) -> Bool {
        func ellipse(centerX: CGFloat, centerY: CGFloat, radiusX: CGFloat, radiusY: CGFloat) -> Bool {
            let dx = (x - centerX) / radiusX
            let dy = (y - centerY) / radiusY
            return (dx * dx) + (dy * dy) <= 1
        }

        func segment(startX: CGFloat, startY: CGFloat, endX: CGFloat, endY: CGFloat, radius: CGFloat) -> Bool {
            let vx = endX - startX
            let vy = endY - startY
            let wx = x - startX
            let wy = y - startY
            let lengthSquared = (vx * vx) + (vy * vy)
            let projection = max(0, min(1, ((wx * vx) + (wy * vy)) / lengthSquared))
            let nearestX = startX + projection * vx
            let nearestY = startY + projection * vy
            let dx = x - nearestX
            let dy = y - nearestY
            return sqrt((dx * dx) + (dy * dy)) <= radius
        }

        let head = ellipse(centerX: 0.50, centerY: 0.12, radiusX: 0.13, radiusY: 0.09)
        let neck = x >= 0.44 && x <= 0.56 && y >= 0.19 && y <= 0.27
        let torso = x >= 0.31 && x <= 0.69 && y >= 0.25 && y <= 0.58
        let leftArm = segment(startX: 0.33, startY: 0.30, endX: 0.18, endY: 0.67, radius: 0.065)
        let rightArm = segment(startX: 0.67, startY: 0.30, endX: 0.82, endY: 0.67, radius: 0.065)
        let leftHand = ellipse(centerX: 0.18, centerY: 0.69, radiusX: 0.07, radiusY: 0.045)
        let rightHand = ellipse(centerX: 0.82, centerY: 0.69, radiusX: 0.07, radiusY: 0.045)
        let leftLeg = segment(startX: 0.43, startY: 0.56, endX: 0.39, endY: 0.92, radius: 0.07)
        let rightLeg = segment(startX: 0.57, startY: 0.56, endX: 0.61, endY: 0.92, radius: 0.07)
        let feet = ellipse(centerX: 0.41, centerY: 0.95, radiusX: 0.07, radiusY: 0.035)
            || ellipse(centerX: 0.59, centerY: 0.95, radiusX: 0.07, radiusY: 0.035)

        return head || neck || torso || leftArm || rightArm || leftHand || rightHand || leftLeg || rightLeg || feet
    }
}

struct ImprovedPainBodySilhouette: View {
    let side: PainBodySide
    let tint: Color

    private let fill = Color(red: 1.00, green: 0.78, blue: 0.84)

    var body: some View {
        GeometryReader { proxy in
            let rect = bodyRect(in: proxy.size)

            ZStack {
                RoundedRectangle(cornerRadius: rect.width * 0.08, style: .continuous)
                    .fill(fill)
                    .frame(width: rect.width * 0.17, height: rect.height * 0.42)
                    .position(x: rect.minX + rect.width * 0.37, y: rect.minY + rect.height * 0.76)

                RoundedRectangle(cornerRadius: rect.width * 0.08, style: .continuous)
                    .fill(fill)
                    .frame(width: rect.width * 0.17, height: rect.height * 0.42)
                    .position(x: rect.minX + rect.width * 0.63, y: rect.minY + rect.height * 0.76)

                RoundedRectangle(cornerRadius: rect.width * 0.08, style: .continuous)
                    .fill(fill)
                    .frame(width: rect.width * 0.12, height: rect.height * 0.39)
                    .position(x: rect.minX + rect.width * 0.15, y: rect.minY + rect.height * 0.47)

                RoundedRectangle(cornerRadius: rect.width * 0.08, style: .continuous)
                    .fill(fill)
                    .frame(width: rect.width * 0.12, height: rect.height * 0.39)
                    .position(x: rect.minX + rect.width * 0.85, y: rect.minY + rect.height * 0.47)

                RoundedRectangle(cornerRadius: rect.width * 0.15, style: .continuous)
                    .fill(fill)
                    .frame(width: rect.width * 0.56, height: rect.height * 0.47)
                    .position(x: rect.midX, y: rect.minY + rect.height * 0.43)

                RoundedRectangle(cornerRadius: rect.width * 0.09, style: .continuous)
                    .fill(fill)
                    .frame(width: rect.width * 0.20, height: rect.height * 0.22)
                    .position(x: rect.midX, y: rect.minY + rect.height * 0.24)

                Circle()
                    .fill(fill)
                    .frame(width: rect.width * 0.33, height: rect.width * 0.33)
                    .position(x: rect.midX, y: rect.minY + rect.height * 0.09)
            }
        }
    }

    private func bodyRect(in size: CGSize) -> CGRect {
        let width = min(size.width * 0.72, size.height * 0.42)
        let height = min(size.height * 0.98, width / 0.42)
        return CGRect(
            x: (size.width - width) / 2,
            y: (size.height - height) / 2,
            width: width,
            height: height
        )
    }

    private func p(_ x: CGFloat, _ y: CGFloat, _ rect: CGRect) -> CGPoint {
        CGPoint(x: rect.minX + rect.width * x, y: rect.minY + rect.height * y)
    }

    private func humanSilhouettePath(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: p(0.50, 0.03, rect))
        path.addCurve(to: p(0.39, 0.06, rect), control1: p(0.45, 0.03, rect), control2: p(0.41, 0.04, rect))
        path.addCurve(to: p(0.36, 0.15, rect), control1: p(0.36, 0.09, rect), control2: p(0.35, 0.12, rect))
        path.addCurve(to: p(0.38, 0.22, rect), control1: p(0.36, 0.18, rect), control2: p(0.37, 0.20, rect))
        path.addCurve(to: p(0.42, 0.24, rect), control1: p(0.39, 0.23, rect), control2: p(0.40, 0.24, rect))
        path.addLine(to: p(0.41, 0.28, rect))
        path.addCurve(to: p(0.31, 0.30, rect), control1: p(0.37, 0.29, rect), control2: p(0.34, 0.29, rect))
        path.addCurve(to: p(0.27, 0.36, rect), control1: p(0.28, 0.31, rect), control2: p(0.27, 0.33, rect))
        path.addCurve(to: p(0.24, 0.54, rect), control1: p(0.27, 0.42, rect), control2: p(0.25, 0.48, rect))
        path.addCurve(to: p(0.18, 0.70, rect), control1: p(0.23, 0.60, rect), control2: p(0.20, 0.65, rect))
        path.addCurve(to: p(0.14, 0.78, rect), control1: p(0.17, 0.73, rect), control2: p(0.15, 0.75, rect))
        path.addCurve(to: p(0.16, 0.84, rect), control1: p(0.12, 0.82, rect), control2: p(0.14, 0.84, rect))
        path.addCurve(to: p(0.20, 0.79, rect), control1: p(0.18, 0.86, rect), control2: p(0.20, 0.83, rect))
        path.addCurve(to: p(0.23, 0.73, rect), control1: p(0.20, 0.77, rect), control2: p(0.21, 0.75, rect))
        path.addCurve(to: p(0.29, 0.57, rect), control1: p(0.25, 0.68, rect), control2: p(0.28, 0.63, rect))
        path.addCurve(to: p(0.34, 0.42, rect), control1: p(0.30, 0.51, rect), control2: p(0.32, 0.46, rect))
        path.addCurve(to: p(0.37, 0.61, rect), control1: p(0.36, 0.50, rect), control2: p(0.36, 0.56, rect))
        path.addCurve(to: p(0.40, 0.67, rect), control1: p(0.38, 0.64, rect), control2: p(0.39, 0.66, rect))
        path.addCurve(to: p(0.36, 0.82, rect), control1: p(0.38, 0.72, rect), control2: p(0.36, 0.77, rect))
        path.addCurve(to: p(0.35, 0.93, rect), control1: p(0.36, 0.87, rect), control2: p(0.36, 0.90, rect))
        path.addCurve(to: p(0.31, 0.98, rect), control1: p(0.34, 0.95, rect), control2: p(0.31, 0.96, rect))
        path.addCurve(to: p(0.45, 0.98, rect), control1: p(0.30, 1.01, rect), control2: p(0.43, 1.00, rect))
        path.addCurve(to: p(0.48, 0.82, rect), control1: p(0.47, 0.93, rect), control2: p(0.47, 0.88, rect))
        path.addCurve(to: p(0.50, 0.67, rect), control1: p(0.48, 0.77, rect), control2: p(0.49, 0.72, rect))
        path.addCurve(to: p(0.52, 0.82, rect), control1: p(0.51, 0.72, rect), control2: p(0.52, 0.77, rect))
        path.addCurve(to: p(0.55, 0.98, rect), control1: p(0.53, 0.88, rect), control2: p(0.53, 0.93, rect))
        path.addCurve(to: p(0.69, 0.98, rect), control1: p(0.57, 1.00, rect), control2: p(0.70, 1.01, rect))
        path.addCurve(to: p(0.65, 0.93, rect), control1: p(0.69, 0.96, rect), control2: p(0.66, 0.95, rect))
        path.addCurve(to: p(0.64, 0.82, rect), control1: p(0.64, 0.90, rect), control2: p(0.64, 0.87, rect))
        path.addCurve(to: p(0.60, 0.67, rect), control1: p(0.64, 0.77, rect), control2: p(0.62, 0.72, rect))
        path.addCurve(to: p(0.63, 0.61, rect), control1: p(0.61, 0.66, rect), control2: p(0.62, 0.64, rect))
        path.addCurve(to: p(0.66, 0.42, rect), control1: p(0.64, 0.56, rect), control2: p(0.64, 0.50, rect))
        path.addCurve(to: p(0.71, 0.57, rect), control1: p(0.68, 0.46, rect), control2: p(0.70, 0.51, rect))
        path.addCurve(to: p(0.77, 0.73, rect), control1: p(0.72, 0.63, rect), control2: p(0.75, 0.68, rect))
        path.addCurve(to: p(0.80, 0.79, rect), control1: p(0.79, 0.75, rect), control2: p(0.80, 0.77, rect))
        path.addCurve(to: p(0.84, 0.84, rect), control1: p(0.80, 0.83, rect), control2: p(0.82, 0.86, rect))
        path.addCurve(to: p(0.86, 0.78, rect), control1: p(0.86, 0.84, rect), control2: p(0.88, 0.82, rect))
        path.addCurve(to: p(0.82, 0.70, rect), control1: p(0.85, 0.75, rect), control2: p(0.83, 0.73, rect))
        path.addCurve(to: p(0.76, 0.54, rect), control1: p(0.80, 0.65, rect), control2: p(0.77, 0.60, rect))
        path.addCurve(to: p(0.73, 0.36, rect), control1: p(0.75, 0.48, rect), control2: p(0.73, 0.42, rect))
        path.addCurve(to: p(0.69, 0.30, rect), control1: p(0.73, 0.33, rect), control2: p(0.72, 0.31, rect))
        path.addCurve(to: p(0.59, 0.28, rect), control1: p(0.66, 0.29, rect), control2: p(0.63, 0.29, rect))
        path.addLine(to: p(0.58, 0.24, rect))
        path.addCurve(to: p(0.62, 0.22, rect), control1: p(0.60, 0.24, rect), control2: p(0.61, 0.23, rect))
        path.addCurve(to: p(0.64, 0.15, rect), control1: p(0.63, 0.20, rect), control2: p(0.64, 0.18, rect))
        path.addCurve(to: p(0.61, 0.06, rect), control1: p(0.65, 0.12, rect), control2: p(0.64, 0.09, rect))
        path.addCurve(to: p(0.50, 0.03, rect), control1: p(0.59, 0.04, rect), control2: p(0.55, 0.03, rect))
        path.closeSubpath()

        return path
    }

    private func bodyPart(_ path: Path) -> some View {
        path
            .fill(fill)
    }

    private func headPath(in rect: CGRect) -> Path {
        Path(ellipseIn: CGRect(
            x: rect.minX + rect.width * 0.36,
            y: rect.minY + rect.height * 0.03,
            width: rect.width * 0.28,
            height: rect.height * 0.16
        ))
    }

    private func neckPath(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: p(0.43, 0.18, rect))
        path.addLine(to: p(0.57, 0.18, rect))
        path.addLine(to: p(0.61, 0.30, rect))
        path.addLine(to: p(0.39, 0.30, rect))
        path.closeSubpath()
        return path
    }

    private func torsoPath(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: p(0.28, 0.29, rect))
        path.addCurve(to: p(0.72, 0.29, rect), control1: p(0.39, 0.25, rect), control2: p(0.61, 0.25, rect))
        path.addCurve(to: p(0.70, 0.51, rect), control1: p(0.76, 0.36, rect), control2: p(0.73, 0.45, rect))
        path.addCurve(to: p(0.62, 0.63, rect), control1: p(0.68, 0.57, rect), control2: p(0.66, 0.61, rect))
        path.addCurve(to: p(0.50, 0.65, rect), control1: p(0.58, 0.65, rect), control2: p(0.54, 0.66, rect))
        path.addCurve(to: p(0.38, 0.63, rect), control1: p(0.46, 0.66, rect), control2: p(0.42, 0.65, rect))
        path.addCurve(to: p(0.30, 0.51, rect), control1: p(0.34, 0.61, rect), control2: p(0.32, 0.57, rect))
        path.addCurve(to: p(0.28, 0.29, rect), control1: p(0.27, 0.45, rect), control2: p(0.24, 0.36, rect))
        path.closeSubpath()
        return path
    }

    private func leftArmPath(in rect: CGRect) -> Path {
        armPath(in: rect, left: true)
    }

    private func rightArmPath(in rect: CGRect) -> Path {
        armPath(in: rect, left: false)
    }

    private func armPath(in rect: CGRect, left: Bool) -> Path {
        func x(_ frontX: CGFloat) -> CGFloat {
            left ? frontX : 1 - frontX
        }

        var path = Path()
        path.move(to: p(x(0.31), 0.31, rect))
        path.addCurve(to: p(x(0.20), 0.60, rect), control1: p(x(0.22), 0.40, rect), control2: p(x(0.23), 0.51, rect))
        path.addCurve(to: p(x(0.10), 0.74, rect), control1: p(x(0.19), 0.66, rect), control2: p(x(0.14), 0.70, rect))
        path.addCurve(to: p(x(0.07), 0.80, rect), control1: p(x(0.06), 0.77, rect), control2: p(x(0.05), 0.79, rect))
        path.addCurve(to: p(x(0.16), 0.80, rect), control1: p(x(0.09), 0.84, rect), control2: p(x(0.14), 0.82, rect))
        path.addCurve(to: p(x(0.21), 0.73, rect), control1: p(x(0.17), 0.86, rect), control2: p(x(0.22), 0.82, rect))
        path.addCurve(to: p(x(0.29), 0.53, rect), control1: p(x(0.22), 0.66, rect), control2: p(x(0.27), 0.60, rect))
        path.addCurve(to: p(x(0.36), 0.34, rect), control1: p(x(0.30), 0.45, rect), control2: p(x(0.33), 0.39, rect))
        path.addCurve(to: p(x(0.31), 0.31, rect), control1: p(x(0.35), 0.32, rect), control2: p(x(0.33), 0.31, rect))
        path.closeSubpath()
        return path
    }

    private func leftLegPath(in rect: CGRect) -> Path {
        legPath(in: rect, left: true)
    }

    private func rightLegPath(in rect: CGRect) -> Path {
        legPath(in: rect, left: false)
    }

    private func legPath(in rect: CGRect, left: Bool) -> Path {
        let hipOuter: CGFloat = left ? 0.38 : 0.62
        let kneeOuter: CGFloat = left ? 0.34 : 0.66
        let ankleOuter: CGFloat = left ? 0.35 : 0.65
        let footOuter: CGFloat = left ? 0.28 : 0.72
        let footInner: CGFloat = left ? 0.48 : 0.52
        let inner: CGFloat = left ? 0.49 : 0.51

        var path = Path()
        path.move(to: p(hipOuter, 0.61, rect))
        path.addCurve(to: p(kneeOuter, 0.79, rect), control1: p(left ? 0.35 : 0.65, 0.68, rect), control2: p(kneeOuter, 0.73, rect))
        path.addCurve(to: p(ankleOuter, 0.93, rect), control1: p(kneeOuter, 0.86, rect), control2: p(ankleOuter, 0.90, rect))
        path.addCurve(to: p(footOuter, 0.97, rect), control1: p(left ? 0.33 : 0.67, 0.95, rect), control2: p(left ? 0.29 : 0.71, 0.95, rect))
        path.addCurve(to: p(footInner, 0.98, rect), control1: p(left ? 0.31 : 0.69, 1.00, rect), control2: p(left ? 0.44 : 0.56, 1.00, rect))
        path.addCurve(to: p(inner, 0.66, rect), control1: p(left ? 0.47 : 0.53, 0.89, rect), control2: p(left ? 0.48 : 0.52, 0.75, rect))
        path.addCurve(to: p(hipOuter, 0.61, rect), control1: p(left ? 0.47 : 0.53, 0.63, rect), control2: p(left ? 0.43 : 0.57, 0.61, rect))
        path.closeSubpath()
        return path
    }

}

struct PainBodySilhouette: View {
    let side: PainBodySide
    let tint: Color

    private let fill = Color(red: 1.00, green: 0.87, blue: 0.90)

    var body: some View {
        GeometryReader { proxy in
            let drawingRect = centeredRect(in: proxy.size)

            ZStack {
                bodyPath(in: drawingRect)
                    .fill(fill)

                bodyPath(in: drawingRect)
                    .stroke(tint.opacity(0.42), style: StrokeStyle(lineWidth: 2.3, lineCap: .round, lineJoin: .round))

                detailPath(in: drawingRect)
                    .stroke(tint.opacity(0.38), style: StrokeStyle(lineWidth: 1.7, lineCap: .round, lineJoin: .round))
            }
        }
    }

    private func centeredRect(in size: CGSize) -> CGRect {
        let width = min(size.width, size.height * 0.52)
        let height = min(size.height, width / 0.52)
        return CGRect(
            x: (size.width - width) / 2,
            y: (size.height - height) / 2,
            width: width,
            height: height
        )
    }

    private func point(_ x: CGFloat, _ y: CGFloat, in rect: CGRect) -> CGPoint {
        CGPoint(x: rect.minX + (rect.width * x), y: rect.minY + (rect.height * y))
    }

    private func bodyPath(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: point(0.50, 0.03, in: rect))
        path.addCurve(to: point(0.36, 0.16, in: rect), control1: point(0.41, 0.03, in: rect), control2: point(0.35, 0.08, in: rect))
        path.addCurve(to: point(0.42, 0.25, in: rect), control1: point(0.36, 0.20, in: rect), control2: point(0.38, 0.23, in: rect))
        path.addLine(to: point(0.39, 0.31, in: rect))
        path.addLine(to: point(0.27, 0.33, in: rect))
        path.addCurve(to: point(0.20, 0.45, in: rect), control1: point(0.22, 0.34, in: rect), control2: point(0.19, 0.38, in: rect))
        path.addCurve(to: point(0.16, 0.65, in: rect), control1: point(0.20, 0.51, in: rect), control2: point(0.16, 0.57, in: rect))
        path.addCurve(to: point(0.07, 0.77, in: rect), control1: point(0.14, 0.71, in: rect), control2: point(0.09, 0.75, in: rect))
        path.addCurve(to: point(0.03, 0.81, in: rect), control1: point(0.03, 0.79, in: rect), control2: point(0.02, 0.81, in: rect))
        path.addCurve(to: point(0.12, 0.81, in: rect), control1: point(0.05, 0.85, in: rect), control2: point(0.09, 0.84, in: rect))
        path.addCurve(to: point(0.16, 0.76, in: rect), control1: point(0.11, 0.86, in: rect), control2: point(0.16, 0.86, in: rect))
        path.addCurve(to: point(0.24, 0.61, in: rect), control1: point(0.18, 0.70, in: rect), control2: point(0.23, 0.66, in: rect))
        path.addCurve(to: point(0.32, 0.47, in: rect), control1: point(0.25, 0.55, in: rect), control2: point(0.31, 0.51, in: rect))
        path.addCurve(to: point(0.34, 0.70, in: rect), control1: point(0.36, 0.55, in: rect), control2: point(0.36, 0.63, in: rect))
        path.addCurve(to: point(0.38, 0.95, in: rect), control1: point(0.34, 0.78, in: rect), control2: point(0.34, 0.88, in: rect))
        path.addCurve(to: point(0.49, 0.96, in: rect), control1: point(0.42, 0.99, in: rect), control2: point(0.47, 0.98, in: rect))
        path.addCurve(to: point(0.50, 0.74, in: rect), control1: point(0.48, 0.87, in: rect), control2: point(0.49, 0.80, in: rect))
        path.addCurve(to: point(0.51, 0.96, in: rect), control1: point(0.51, 0.80, in: rect), control2: point(0.52, 0.87, in: rect))
        path.addCurve(to: point(0.62, 0.95, in: rect), control1: point(0.53, 0.98, in: rect), control2: point(0.58, 0.99, in: rect))
        path.addCurve(to: point(0.66, 0.70, in: rect), control1: point(0.66, 0.88, in: rect), control2: point(0.66, 0.78, in: rect))
        path.addCurve(to: point(0.68, 0.47, in: rect), control1: point(0.64, 0.63, in: rect), control2: point(0.64, 0.55, in: rect))
        path.addCurve(to: point(0.76, 0.61, in: rect), control1: point(0.69, 0.51, in: rect), control2: point(0.75, 0.55, in: rect))
        path.addCurve(to: point(0.84, 0.76, in: rect), control1: point(0.77, 0.66, in: rect), control2: point(0.82, 0.70, in: rect))
        path.addCurve(to: point(0.88, 0.81, in: rect), control1: point(0.84, 0.86, in: rect), control2: point(0.89, 0.86, in: rect))
        path.addCurve(to: point(0.97, 0.81, in: rect), control1: point(0.91, 0.84, in: rect), control2: point(0.95, 0.85, in: rect))
        path.addCurve(to: point(0.93, 0.77, in: rect), control1: point(0.98, 0.81, in: rect), control2: point(0.97, 0.79, in: rect))
        path.addCurve(to: point(0.84, 0.65, in: rect), control1: point(0.91, 0.75, in: rect), control2: point(0.86, 0.71, in: rect))
        path.addCurve(to: point(0.80, 0.45, in: rect), control1: point(0.84, 0.57, in: rect), control2: point(0.80, 0.51, in: rect))
        path.addCurve(to: point(0.73, 0.33, in: rect), control1: point(0.81, 0.38, in: rect), control2: point(0.78, 0.34, in: rect))
        path.addLine(to: point(0.61, 0.31, in: rect))
        path.addLine(to: point(0.58, 0.25, in: rect))
        path.addCurve(to: point(0.64, 0.16, in: rect), control1: point(0.62, 0.23, in: rect), control2: point(0.64, 0.20, in: rect))
        path.addCurve(to: point(0.50, 0.03, in: rect), control1: point(0.65, 0.08, in: rect), control2: point(0.59, 0.03, in: rect))
        path.closeSubpath()

        return path
    }

    private func detailPath(in rect: CGRect) -> Path {
        var path = Path()

        if side == .front {
            path.move(to: point(0.32, 0.45, in: rect))
            path.addQuadCurve(to: point(0.46, 0.45, in: rect), control: point(0.39, 0.51, in: rect))
            path.move(to: point(0.54, 0.45, in: rect))
            path.addQuadCurve(to: point(0.68, 0.45, in: rect), control: point(0.61, 0.51, in: rect))
            path.move(to: point(0.50, 0.56, in: rect))
            path.addQuadCurve(to: point(0.50, 0.57, in: rect), control: point(0.49, 0.57, in: rect))
            path.move(to: point(0.40, 0.74, in: rect))
            path.addQuadCurve(to: point(0.46, 0.73, in: rect), control: point(0.43, 0.77, in: rect))
            path.move(to: point(0.60, 0.74, in: rect))
            path.addQuadCurve(to: point(0.54, 0.73, in: rect), control: point(0.57, 0.77, in: rect))
            path.move(to: point(0.42, 0.88, in: rect))
            path.addQuadCurve(to: point(0.35, 0.88, in: rect), control: point(0.38, 0.86, in: rect))
            path.move(to: point(0.58, 0.88, in: rect))
            path.addQuadCurve(to: point(0.65, 0.88, in: rect), control: point(0.62, 0.86, in: rect))
        } else {
            path.move(to: point(0.50, 0.31, in: rect))
            path.addLine(to: point(0.50, 0.63, in: rect))
            path.move(to: point(0.35, 0.43, in: rect))
            path.addQuadCurve(to: point(0.45, 0.35, in: rect), control: point(0.44, 0.44, in: rect))
            path.move(to: point(0.65, 0.43, in: rect))
            path.addQuadCurve(to: point(0.55, 0.35, in: rect), control: point(0.56, 0.44, in: rect))
            path.move(to: point(0.36, 0.72, in: rect))
            path.addQuadCurve(to: point(0.49, 0.71, in: rect), control: point(0.42, 0.76, in: rect))
            path.move(to: point(0.64, 0.72, in: rect))
            path.addQuadCurve(to: point(0.51, 0.71, in: rect), control: point(0.58, 0.76, in: rect))
            path.move(to: point(0.42, 0.88, in: rect))
            path.addQuadCurve(to: point(0.35, 0.88, in: rect), control: point(0.38, 0.86, in: rect))
            path.move(to: point(0.58, 0.88, in: rect))
            path.addQuadCurve(to: point(0.65, 0.88, in: rect), control: point(0.62, 0.86, in: rect))
        }

        return path
    }
}

struct SeizureTimerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let option: QuickLogOption
    let initialSeizureType: String
    let onSave: (HealthLogEntry) -> Void

    @State private var startTime = Date()
    @State private var elapsedSeconds = 0
    @State private var isRunning = true
    @State private var isStopped = false
    @State private var severity = 3.0
    @State private var seizureType = "Seizure Type"
    @State private var triggers = ""
    @State private var postEventNotes = ""
    @State private var showingDeleteConfirmation = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let seizureTypes = [
        "Seizure Type",
        "Focal",
        "Absence",
        "Tonic-clonic",
        "Atonic",
        "Myoclonic",
        "Infantile spasm",
        "Other"
    ]

    private var defaultSeizureType: String {
        seizureTypes.contains(initialSeizureType) ? initialSeizureType : "Seizure Type"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(spacing: 12) {
                        Image(systemName: option.icon)
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(option.tint)
                            .frame(width: 70, height: 70)
                            .background(option.tint.opacity(0.16))
                            .clipShape(Circle())

                        Text(durationText(elapsedSeconds))
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(AppTheme.text)

                        Text(isStopped ? "Timer stopped" : (isRunning ? "Timer running" : "Timer paused"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(18)
                    .background(AppTheme.panel)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    HStack(spacing: 12) {
                        Button {
                            isRunning.toggle()
                        } label: {
                            Text(isRunning ? "Pause" : "Resume")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.accent)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.accent.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .disabled(isStopped)

                        Button {
                            isRunning = false
                            isStopped = true
                        } label: {
                            Text("Stop")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .disabled(isStopped)
                    }

                    if !isStopped {
                        Button {
                            skipTimer()
                        } label: {
                            Text("Skip")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.accent)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.fieldBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }

                    if isStopped {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Seizure Details")
                                .font(.headline.weight(.bold))

                            VStack(alignment: .leading, spacing: 10) {
                                Text("Duration")
                                    .font(.subheadline.weight(.semibold))

                                HStack(spacing: 10) {
                                    DurationNumberField(title: "Minutes", value: durationMinutesBinding)
                                    DurationNumberField(title: "Seconds", value: durationSecondsBinding)
                                }

                                Stepper("Fine tune: \(durationText(elapsedSeconds))", value: $elapsedSeconds, in: 0...7200, step: 1)
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }

                            Picker("Seizure Type", selection: $seizureType) {
                                ForEach(seizureTypes, id: \.self) { type in
                                    Text(type).tag(type)
                                }
                            }
                            .pickerStyle(.menu)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Severity: \(Int(severity))/5")
                                    .font(.subheadline.weight(.semibold))
                                Slider(value: $severity, in: 1...5, step: 1)
                                    .tint(option.tint)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Triggers")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.text)

                                TextField("Flashing lights, missed sleep, heat, illness, etc.", text: $triggers, axis: .vertical)
                                    .lineLimit(3...6)
                                    .padding(12)
                                    .background(AppTheme.fieldBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Post-event Notes")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.text)

                                TextField("Recovery, breathing, color, awareness, what helped", text: $postEventNotes, axis: .vertical)
                                    .lineLimit(4...7)
                                    .padding(12)
                                    .background(AppTheme.fieldBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }

                            HStack(spacing: 12) {
                                Button(role: .destructive) {
                                    showingDeleteConfirmation = true
                                } label: {
                                    Text("Delete")
                                        .font(.headline.weight(.bold))
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.red.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }

                                Button {
                                    save()
                                } label: {
                                    Text("Save")
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(AppTheme.accent)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                            }
                        }
                        .authPanel()
                    }
                }
                .padding(18)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Seizure Track")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        if isStopped {
                            showingDeleteConfirmation = true
                        } else {
                            dismiss()
                        }
                    }
                }
            }
            .confirmationDialog(
                "Delete this seizure timer?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Timer", role: .destructive) {
                    dismiss()
                }
                Button("Keep Editing", role: .cancel) {
                }
            } message: {
                Text("This timer has not been saved.")
            }
        }
        .presentationDetents([.large])
        .onReceive(timer) { _ in
            guard isRunning, !isStopped else { return }
            elapsedSeconds += 1
        }
        .onAppear {
            startTime = Date()
            elapsedSeconds = 0
            isRunning = true
            isStopped = false
            seizureType = defaultSeizureType
        }
    }

    private func skipTimer() {
        elapsedSeconds = 0
        isRunning = false
        isStopped = true
    }

    private var durationMinutesBinding: Binding<Int> {
        Binding(
            get: { elapsedSeconds / 60 },
            set: { newValue in
                let minutes = min(max(newValue, 0), 120)
                elapsedSeconds = min((minutes * 60) + durationSecondsBinding.wrappedValue, 7200)
            }
        )
    }

    private var durationSecondsBinding: Binding<Int> {
        Binding(
            get: { elapsedSeconds % 60 },
            set: { newValue in
                let seconds = min(max(newValue, 0), 59)
                elapsedSeconds = min(((elapsedSeconds / 60) * 60) + seconds, 7200)
            }
        )
    }

    private func save() {
        let comments = [
            triggers.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : "Triggers: \(triggers.trimmingCharacters(in: .whitespacesAndNewlines))",
            postEventNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : "Post-event notes: \(postEventNotes.trimmingCharacters(in: .whitespacesAndNewlines))"
        ]
        .compactMap { $0 }
        .joined(separator: "\n\n")

        let entry = HealthLogEntry(
            id: UUID(),
            type: .quickLog,
            categoryID: option.id,
            title: option.title,
            timestamp: startTime,
            severity: Int(severity),
            value: "\(durationText(elapsedSeconds)) · \(seizureType)",
            comments: comments
        )
        onSave(entry)
        dismiss()
    }

    private func durationText(_ totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct DurationNumberField: View {
    let title: String
    @Binding var value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField("0", value: $value, format: .number)
                .keyboardType(.numberPad)
                .font(.title3.weight(.bold))
                .monospacedDigit()
                .multilineTextAlignment(.center)
                .padding(.vertical, 12)
                .padding(.horizontal, 10)
                .background(AppTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .frame(maxWidth: .infinity)
    }
}

struct HealthTrendChart: View {
    let entries: [HealthLogEntry]

    private var recentEntries: [HealthLogEntry] {
        Array(entries.sorted { $0.timestamp < $1.timestamp }.suffix(12))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if recentEntries.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No trend data yet")
                        .font(.headline.weight(.bold))

                    Text("Tap a quick-log or daily snapshot card to save the first entry.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(AppTheme.panel)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                Chart(recentEntries) { entry in
                    BarMark(
                        x: .value("Entry", entry.timestamp, unit: .minute),
                        y: .value("Severity", entry.severity)
                    )
                    .foregroundStyle(by: .value("Type", entry.title))
                }
                .chartYScale(domain: 0...5)
                .chartYAxis {
                    AxisMarks(values: [1, 2, 3, 4, 5])
                }
                .frame(height: 180)
                .padding(14)
                .background(AppTheme.panel)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(spacing: 8) {
                    ForEach(recentEntries.suffix(3).reversed()) { entry in
                        TrendEntryRow(entry: entry)
                    }
                }
            }
        }
    }
}

struct QuickLogTrendsView: View {
    let options: [QuickLogOption]
    let entries: [HealthLogEntry]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if options.isEmpty {
                    Text("Choose quick-log buttons on the dashboard to see history here.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .authPanel()
                } else {
                    LazyVStack(spacing: 14) {
                        ForEach(options) { option in
                            QuickLogTrendPreviewCard(
                                option: option,
                                entries: entriesFor(option)
                            )
                        }
                    }
                }
            }
            .padding(18)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func entriesFor(_ option: QuickLogOption) -> [HealthLogEntry] {
        entries
            .filter { $0.type == .quickLog && $0.categoryID == option.id }
            .sorted { $0.timestamp < $1.timestamp }
    }
}

struct QuickLogTrendPreviewCard: View {
    let option: QuickLogOption
    let entries: [HealthLogEntry]

    private var recentEntries: [HealthLogEntry] {
        Array(entries.suffix(8))
    }

    private var averageSeverity: Double {
        guard !entries.isEmpty else { return 0 }
        let total = entries.reduce(0) { $0 + $1.severity }
        return Double(total) / Double(entries.count)
    }

    var body: some View {
        if option.id == "seizure" {
            NavigationLink {
                SeizureHistoryDetailView(option: option, entries: entries)
            } label: {
                seizureHistoryCard
            }
            .buttonStyle(.plain)
        } else {
            Button {
            } label: {
                trendChartCard
            }
            .buttonStyle(.plain)
        }
    }

    private var cardHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: option.icon)
                .font(.title2.weight(.bold))
                .foregroundStyle(option.tint)
                .frame(width: 48, height: 48)
                .background(option.tint.opacity(0.16))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(option.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.text)

                Text("\(entries.count) entries · Avg \(averageSeverityText)/5")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
        }
    }

    private var trendChartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            cardHeader

            chartPreview
                .frame(height: 110)
                .padding(10)
                .background(AppTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
    }

    private var seizureHistoryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            cardHeader

            HStack(spacing: 10) {
                Image(systemName: "list.bullet.clipboard")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(option.tint)
                    .frame(width: 36, height: 36)
                    .background(option.tint.opacity(0.14))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(entries.count) saved logs")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppTheme.text)

                    Text("Dates, times, duration, type, triggers, and notes")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(12)
            .background(AppTheme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
    }

    @ViewBuilder
    private var chartPreview: some View {
        if recentEntries.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "chart.bar")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(option.tint)

                Text("No data yet")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Chart(recentEntries) { entry in
                LineMark(
                    x: .value("Time", entry.timestamp),
                    y: .value("Severity", entry.severity)
                )
                .foregroundStyle(option.tint)
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Time", entry.timestamp),
                    y: .value("Severity", entry.severity)
                )
                .foregroundStyle(option.tint)
            }
            .chartYScale(domain: 0...5)
            .chartYAxis {
                AxisMarks(values: [1, 3, 5])
            }
            .chartXAxis(.hidden)
        }
    }

    private var averageSeverityText: String {
        averageSeverity == 0 ? "0" : String(format: "%.1f", averageSeverity)
    }
}

struct SnapshotHistoryView: View {
    let options: [SnapshotOption]
    let entries: [HealthLogEntry]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(options) { option in
                    SnapshotHistoryPreviewCard(
                        option: option,
                        entries: entriesFor(option)
                    )
                }
            }
            .padding(18)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func entriesFor(_ option: SnapshotOption) -> [HealthLogEntry] {
        entries
            .filter { $0.type == .snapshot && $0.categoryID == option.id }
            .sorted { $0.timestamp < $1.timestamp }
    }
}

struct SnapshotHistoryPreviewCard: View {
    let option: SnapshotOption
    let entries: [HealthLogEntry]

    private var recentEntries: [HealthLogEntry] {
        Array(entries.suffix(8))
    }

    private var averageSeverity: Double {
        guard !entries.isEmpty else { return 0 }
        let total = entries.reduce(0) { $0 + $1.severity }
        return Double(total) / Double(entries.count)
    }

    var body: some View {
        if option.id == "sleep" {
            NavigationLink {
                SleepTrackerHistoryView(option: option, entries: entries)
            } label: {
                sleepTrackerCard
            }
            .buttonStyle(.plain)
        } else {
            VStack(alignment: .leading, spacing: 14) {
                cardHeader

                chartPreview
                    .frame(height: 110)
                    .padding(10)
                    .background(AppTheme.fieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .snapshotHistoryCardStyle()
        }
    }

    private var cardHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: option.icon)
                .font(.title2.weight(.bold))
                .foregroundStyle(option.tint)
                .frame(width: 48, height: 48)
                .background(option.tint.opacity(0.16))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(option.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.text)

                Text("\(entries.count) entries · Avg \(averageSeverityText)/5")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
        }
    }

    private var sleepTrackerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            cardHeader

            HStack(spacing: 10) {
                Image(systemName: "bed.double.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(option.tint)
                    .frame(width: 36, height: 36)
                    .background(option.tint.opacity(0.14))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(entries.count) nights tracked")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppTheme.text)

                    Text("Sleep times and nightly duration")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(12)
            .background(AppTheme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .snapshotHistoryCardStyle()
    }

    @ViewBuilder
    private var chartPreview: some View {
        if recentEntries.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "chart.bar")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(option.tint)

                Text("No data yet")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Chart(recentEntries) { entry in
                LineMark(
                    x: .value("Time", entry.timestamp),
                    y: .value("Severity", entry.severity)
                )
                .foregroundStyle(option.tint)
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Time", entry.timestamp),
                    y: .value("Severity", entry.severity)
                )
                .foregroundStyle(option.tint)
            }
            .chartYScale(domain: 0...5)
            .chartYAxis {
                AxisMarks(values: [1, 3, 5])
            }
            .chartXAxis(.hidden)
        }
    }

    private var averageSeverityText: String {
        averageSeverity == 0 ? "0" : String(format: "%.1f", averageSeverity)
    }
}

private extension View {
    func snapshotHistoryCardStyle() -> some View {
        self
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.panel)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
    }
}

struct SleepTrackerHistoryView: View {
    let option: SnapshotOption
    let entries: [HealthLogEntry]

    private let timelineWidth: CGFloat = 760
    private let dateColumnWidth: CGFloat = 58
    private let rowHeight: CGFloat = 42
    private let timelineStartMinutes = 18 * 60
    private let timelineEndMinutes = 33 * 60

    private var sleepRecords: [SleepTrackerRecord] {
        entries
            .compactMap(SleepTrackerRecord.init(entry:))
            .sorted { $0.date > $1.date }
    }

    private var hourMarks: [Int] {
        Array(18...33)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if sleepRecords.isEmpty {
                    Text("No Sleep & Rest entries yet.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .authPanel()
                } else {
                    ScrollView(.horizontal, showsIndicators: true) {
                        VStack(alignment: .leading, spacing: 0) {
                            timelineHeader

                            ForEach(sleepRecords) { record in
                                SleepTrackerTimelineRow(
                                    record: record,
                                    tint: option.tint,
                                    dateColumnWidth: dateColumnWidth,
                                    timelineWidth: timelineWidth,
                                    rowHeight: rowHeight,
                                    startMinutes: timelineStartMinutes,
                                    endMinutes: timelineEndMinutes
                                )
                            }
                        }
                        .padding(14)
                        .background(AppTheme.panel)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
                    }
                }
            }
            .padding(18)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Sleep & Rest")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var timelineHeader: some View {
        HStack(alignment: .bottom, spacing: 0) {
            Text("Date")
                .font(.caption.weight(.black))
                .foregroundStyle(.secondary)
                .frame(width: dateColumnWidth, alignment: .leading)

            ZStack(alignment: .bottomLeading) {
                ForEach(hourMarks, id: \.self) { hour in
                    let x = xPosition(for: hour * 60)

                    VStack(spacing: 4) {
                        Text(hourLabel(hour))
                            .font(.caption2.weight(.black))
                            .foregroundStyle(AppTheme.text)

                        Rectangle()
                            .fill(Color.secondary.opacity(0.25))
                            .frame(width: 1, height: 10)
                    }
                    .position(x: x, y: 16)
                }

                Rectangle()
                    .fill(Color.secondary.opacity(0.22))
                    .frame(width: timelineWidth, height: 1)
                    .offset(y: 31)
            }
            .frame(width: timelineWidth, height: 34, alignment: .leading)
        }
        .padding(.bottom, 6)
    }

    private func xPosition(for minutes: Int) -> CGFloat {
        let clamped = min(max(minutes, timelineStartMinutes), timelineEndMinutes)
        let percentage = CGFloat(clamped - timelineStartMinutes) / CGFloat(timelineEndMinutes - timelineStartMinutes)
        return timelineWidth * percentage
    }

    private func hourLabel(_ hour: Int) -> String {
        let normalized = hour % 24
        switch normalized {
        case 0:
            return "12a"
        case 1...11:
            return "\(normalized)a"
        case 12:
            return "12p"
        default:
            return "\(normalized - 12)p"
        }
    }
}

struct SleepTrackerTimelineRow: View {
    let record: SleepTrackerRecord
    let tint: Color
    let dateColumnWidth: CGFloat
    let timelineWidth: CGFloat
    let rowHeight: CGFloat
    let startMinutes: Int
    let endMinutes: Int

    private var barStartX: CGFloat {
        xPosition(for: record.startMinutes)
    }

    private var barEndX: CGFloat {
        xPosition(for: record.endMinutes)
    }

    private var barWidth: CGFloat {
        max(10, barEndX - barStartX)
    }

    var body: some View {
        HStack(spacing: 0) {
            Text(record.dateLabel)
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.text)
                .frame(width: dateColumnWidth, alignment: .leading)

            ZStack(alignment: .leading) {
                ForEach(Array(stride(from: startMinutes, through: endMinutes, by: 60)), id: \.self) { minute in
                    Rectangle()
                        .fill(Color.secondary.opacity(0.09))
                        .frame(width: 1, height: rowHeight)
                        .offset(x: xPosition(for: minute))
                }

                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(tint.opacity(0.30))
                    .frame(width: barWidth, height: 22)
                    .overlay(alignment: .center) {
                        Text(record.durationText)
                            .font(.caption.weight(.black))
                            .foregroundStyle(AppTheme.text)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .offset(x: barStartX)
            }
            .frame(width: timelineWidth, height: rowHeight, alignment: .leading)
        }
    }

    private func xPosition(for minutes: Int) -> CGFloat {
        let clamped = min(max(minutes, startMinutes), endMinutes)
        let percentage = CGFloat(clamped - startMinutes) / CGFloat(endMinutes - startMinutes)
        return timelineWidth * percentage
    }
}

struct SleepTrackerRecord: Identifiable {
    let id: UUID
    let date: Date
    let startMinutes: Int
    let endMinutes: Int
    let durationText: String

    var dateLabel: String {
        date.formatted(.dateTime.month(.abbreviated).day())
    }

    init?(entry: HealthLogEntry) {
        guard entry.type == .snapshot, entry.categoryID == "sleep" else { return nil }

        self.id = entry.id
        self.date = entry.timestamp
        self.durationText = Self.durationText(from: entry.value)

        let lines = entry.comments
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        let sleepMinutes = lines
            .first { $0.localizedCaseInsensitiveContains("fell asleep at") }
            .flatMap { Self.minutesFromLine($0, prefix: "Fell asleep at") } ?? (21 * 60)

        let wakeMinutesRaw = lines
            .first { $0.localizedCaseInsensitiveContains("woke up at") }
            .flatMap { Self.minutesFromLine($0, prefix: "Woke up at") } ?? (7 * 60)

        self.startMinutes = sleepMinutes < 18 * 60 ? sleepMinutes + 24 * 60 : sleepMinutes
        let wakeMinutes = wakeMinutesRaw <= sleepMinutes ? wakeMinutesRaw + 24 * 60 : wakeMinutesRaw
        self.endMinutes = wakeMinutes
    }

    private static func durationText(from value: String) -> String {
        value
            .components(separatedBy: "·")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? "Sleep"
    }

    private static func minutesFromLine(_ line: String, prefix: String) -> Int? {
        let rawTime = line
            .replacingOccurrences(of: prefix, with: "", options: [.caseInsensitive])
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\u{202F}", with: " ")
            .replacingOccurrences(of: "\u{00A0}", with: " ")

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"

        guard let parsed = formatter.date(from: rawTime) else { return nil }
        let components = Calendar.current.dateComponents([.hour, .minute], from: parsed)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }
}

struct SeizureHistoryDetailView: View {
    let option: QuickLogOption
    let entries: [HealthLogEntry]

    private var sortedEntries: [HealthLogEntry] {
        entries.sorted { $0.timestamp > $1.timestamp }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if sortedEntries.isEmpty {
                    Text("No seizure logs saved yet.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .authPanel()
                } else {
                    ForEach(sortedEntries) { entry in
                        SeizureHistoryLogCard(entry: entry, tint: option.tint)
                    }
                }
            }
            .padding(18)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Seizure History")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SeizureHistoryLogCard: View {
    let entry: HealthLogEntry
    let tint: Color

    private var valueParts: [String] {
        entry.value
            .components(separatedBy: "·")
            .map { clean($0) }
    }

    private var duration: String? {
        guard let candidate = valueParts.first, durationSeconds(candidate) > 0 else { return nil }
        return candidate
    }

    private var seizureType: String? {
        guard valueParts.count > 1 else { return nil }
        let candidate = valueParts[1]
        guard !candidate.isEmpty, candidate != "Seizure Type" else { return nil }
        return candidate
    }

    private var triggers: String? {
        commentValue(prefix: "Triggers:")
    }

    private var memoNotes: String? {
        commentValue(prefix: "Post-event notes:") ?? commentValue(prefix: "Memo notes:")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "timer")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(tint)
                    .frame(width: 42, height: 42)
                    .background(tint.opacity(0.15))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.timestamp, format: .dateTime.month().day().year())
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.text)

                    Text(entry.timestamp, format: .dateTime.hour().minute())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(entry.severity)/5")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(tint)
                    .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 8) {
                if let duration {
                    SeizureHistoryDetailRow(title: "Duration", value: duration)
                }

                if let seizureType {
                    SeizureHistoryDetailRow(title: "Seizure Type", value: seizureType)
                }

                if let triggers {
                    SeizureHistoryDetailRow(title: "Triggers", value: triggers)
                }

                if let memoNotes {
                    SeizureHistoryDetailRow(title: "Memo Notes", value: memoNotes)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
    }

    private func commentValue(prefix: String) -> String? {
        let matches = entry.comments
            .components(separatedBy: "\n\n")
            .map { clean($0) }
            .first { $0.range(of: prefix, options: [.anchored, .caseInsensitive]) != nil }

        guard let matches else { return nil }
        let value = clean(String(matches.dropFirst(prefix.count)))
        return value.isEmpty ? nil : value
    }

    private func durationSeconds(_ text: String) -> Int {
        let pieces = text.split(separator: ":").compactMap { Int($0) }

        if pieces.count == 2 {
            return pieces[0] * 60 + pieces[1]
        }

        if pieces.count == 3 {
            return pieces[0] * 3600 + pieces[1] * 60 + pieces[2]
        }

        return 0
    }

    private func clean(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct SeizureHistoryDetailRow: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption.weight(.black))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct TrendEntryRow: View {
    let entry: HealthLogEntry

    var body: some View {
        HStack(spacing: 10) {
            Text("\(entry.severity)/5")
                .font(.caption.weight(.black))
                .foregroundStyle(.white)
                .frame(width: 42, height: 28)
                .background(AppTheme.accent)
                .clipShape(Capsule())

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.text)

                Text(entry.timestamp, style: .time)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !entry.value.isEmpty {
                Text(entry.value)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(10)
        .background(AppTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct InsightCard: View {
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(title)
                .font(.caption.weight(.black))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 58, alignment: .leading)

            Text(message)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct TherapyTrackingView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    PageHeader(
                        icon: "figure.mind.and.body",
                        title: "Therapy Tracking",
                        subtitle: "Track therapies, exercises, routines, and support goals."
                    )

                    VStack(alignment: .leading, spacing: 12) {
                        TrackingRow(title: "Morning routine", detail: "Not started", color: .orange)
                        TrackingRow(title: "Calming practice", detail: "Not started", color: AppTheme.accent)
                        TrackingRow(title: "Therapy notes", detail: "No notes yet", color: .purple)
                    }
                    .authPanel()
                }
                .padding(20)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Therapy")
        }
    }
}

struct NutrientView: View {
    let user: CarePortalUser

    @AppStorage private var mealPhotoData: Data
    @AppStorage private var mealEstimateData: Data
    @State private var selectedMealPhoto: PhotosPickerItem?
    @State private var isEstimating = false
    @State private var estimateError = ""

    init(user: CarePortalUser) {
        self.user = user
        self._mealPhotoData = AppStorage(wrappedValue: Data(), "nutrient.\(user.id).mealPhotoData")
        self._mealEstimateData = AppStorage(wrappedValue: Data(), "nutrient.\(user.id).mealEstimateData")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    PageHeader(
                        icon: "leaf",
                        title: "Nutrient",
                        subtitle: "Estimate meals, hydration, safe foods, and feeding patterns."
                    )

                    VStack(alignment: .leading, spacing: 16) {
                        PhotosPicker(selection: $selectedMealPhoto, matching: .images) {
                            MealPhotoUploadPanel(imageData: mealPhotoData)
                        }
                        .buttonStyle(.plain)

                        Button {
                            estimateMeal()
                        } label: {
                            HStack {
                                if isEstimating {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "sparkles")
                                }

                                Text(isEstimating ? "Estimating..." : "Estimate Nutrients")
                                    .font(.headline.weight(.bold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(mealPhotoData.isEmpty ? Color.gray.opacity(0.45) : AppTheme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .disabled(mealPhotoData.isEmpty || isEstimating)

                        if !estimateError.isEmpty {
                            Text(estimateError)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.red)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if let estimate = mealEstimate {
                            MealNutritionEstimateView(estimate: estimate)
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                HealthMetricRow(icon: "fork.knife", title: "Meals", value: "0 analyzed")
                                HealthMetricRow(icon: "flame.fill", title: "Calories", value: "--")
                                HealthMetricRow(icon: "chart.pie.fill", title: "Macros", value: "--")
                            }
                        }
                    }
                    .authPanel()
                }
                .padding(20)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Nutrient")
            .task(id: selectedMealPhoto) {
                await loadSelectedMealPhoto()
            }
        }
    }

    private var mealEstimate: MealNutritionEstimate? {
        guard !mealEstimateData.isEmpty else { return nil }
        return try? JSONDecoder().decode(MealNutritionEstimate.self, from: mealEstimateData)
    }

    private func loadSelectedMealPhoto() async {
        guard let selectedMealPhoto else { return }

        do {
            if let data = try await selectedMealPhoto.loadTransferable(type: Data.self) {
                mealPhotoData = data
                mealEstimateData = Data()
                estimateError = ""
            }
        } catch {
            // Photo selection is user-driven; keeping the existing photo avoids data loss.
        }
    }

    private func estimateMeal() {
        guard !mealPhotoData.isEmpty else { return }

        isEstimating = true
        estimateError = ""

        Task {
            do {
                let estimate = try await NutritionAPI().analyzeMeal(imageData: mealImageDataURL())
                await MainActor.run {
                    if let data = try? JSONEncoder().encode(estimate) {
                        mealEstimateData = data
                    }
                    isEstimating = false
                }
            } catch {
                await MainActor.run {
                    estimateError = error.localizedDescription
                    isEstimating = false
                }
            }
        }
    }

    private func mealImageDataURL() -> String {
        if let image = UIImage(data: mealPhotoData),
           let jpegData = image.resizedForMealAnalysis(maxDimension: 1200).jpegData(compressionQuality: 0.74) {
            return "data:image/jpeg;base64,\(jpegData.base64EncodedString())"
        }

        return "data:image/jpeg;base64,\(mealPhotoData.base64EncodedString())"
    }
}

struct MealNutritionEstimate: Codable {
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let fiber: Int
    let sugar: Int
    let confidence: String
    let summary: String
    let recommendations: [String]
    let notes: [String]

    enum CodingKeys: String, CodingKey {
        case calories
        case protein
        case carbs
        case fat
        case fiber
        case sugar
        case confidence
        case summary
        case recommendations
        case notes
    }

    init(
        calories: Int,
        protein: Int,
        carbs: Int,
        fat: Int,
        fiber: Int,
        sugar: Int,
        confidence: String,
        summary: String,
        recommendations: [String],
        notes: [String]
    ) {
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.confidence = confidence
        self.summary = summary
        self.recommendations = recommendations
        self.notes = notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        calories = try container.decode(Int.self, forKey: .calories)
        protein = try container.decode(Int.self, forKey: .protein)
        carbs = try container.decode(Int.self, forKey: .carbs)
        fat = try container.decode(Int.self, forKey: .fat)
        fiber = try container.decode(Int.self, forKey: .fiber)
        sugar = try container.decode(Int.self, forKey: .sugar)
        confidence = try container.decode(String.self, forKey: .confidence)
        summary = try container.decodeIfPresent(String.self, forKey: .summary) ?? "This is a photo-based meal estimate."
        recommendations = try container.decodeIfPresent([String].self, forKey: .recommendations) ?? []
        notes = try container.decodeIfPresent([String].self, forKey: .notes) ?? []
    }
}

extension UIImage {
    func resizedForMealAnalysis(maxDimension: CGFloat) -> UIImage {
        let largestSide = max(size.width, size.height)
        guard largestSide > maxDimension else { return self }

        let scale = maxDimension / largestSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        return UIGraphicsImageRenderer(size: newSize).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

struct MealPhotoUploadPanel: View {
    let imageData: Data

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.fieldBackground)

            if let image = mealImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 230)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)

                    Text("Upload Meal Photo")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.text)

                    Text("Breakfast, lunch, dinner, or snack")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 230)
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: imageData.isEmpty ? "plus" : "camera.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(AppTheme.accent)
                        .clipShape(Circle())
                        .padding(12)
                }
            }
        }
        .frame(height: 230)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var mealImage: UIImage? {
        guard !imageData.isEmpty else { return nil }
        return UIImage(data: imageData)
    }
}

struct MealNutritionEstimateView: View {
    let estimate: MealNutritionEstimate

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Estimate")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.text)

                    Text(estimate.confidence)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "sparkles")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.accent)
            }

            HStack(spacing: 12) {
                MetricCard(title: "Calories", value: "\(estimate.calories)", unit: "kcal", icon: "flame.fill")
                MetricCard(title: "Protein", value: "\(estimate.protein)", unit: "g", icon: "bolt.heart.fill")
            }

            MealReportTextSection(
                title: "Summary",
                icon: "text.alignleft",
                text: estimate.summary
            )

            MealReportListSection(
                title: "Recommendations",
                icon: "lightbulb.fill",
                items: estimate.recommendations
            )

            VStack(alignment: .leading, spacing: 12) {
                HealthMetricRow(icon: "leaf.fill", title: "Carbs", value: "\(estimate.carbs) g")
                HealthMetricRow(icon: "drop.fill", title: "Fat", value: "\(estimate.fat) g")
                HealthMetricRow(icon: "circle.hexagongrid.fill", title: "Fiber", value: "\(estimate.fiber) g")
                HealthMetricRow(icon: "cube.fill", title: "Sugar", value: "\(estimate.sugar) g")
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(estimate.notes, id: \.self) { note in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppTheme.accent)

                        Text(note)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

struct MealReportTextSection: View {
    let title: String
    let icon: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.text)

            Text(text.isEmpty ? "No summary available." : text)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(AppTheme.fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct MealReportListSection: View {
    let title: String
    let icon: String
    let items: [String]

    private var displayItems: [String] {
        items.isEmpty ? ["No recommendations available."] : items
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.text)

            ForEach(displayItems, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.accent)

                    Text(item)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(12)
        .background(AppTheme.fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct CommunityView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    PageHeader(
                        icon: "person.3",
                        title: "Community",
                        subtitle: "Keep family, providers, school, and support contacts together."
                    )

                    VStack(alignment: .leading, spacing: 12) {
                        TrackingRow(title: "Care team", detail: "No provider notes yet", color: AppTheme.accent)
                        TrackingRow(title: "School support", detail: "No updates yet", color: .blue)
                        TrackingRow(title: "Family updates", detail: "No updates yet", color: .pink)
                    }
                    .authPanel()
                }
                .padding(20)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Community")
        }
    }
}

struct ProfileView: View {
    let user: CarePortalUser
    let logout: () -> Void

    @State private var selectedPhoto: PhotosPickerItem?
    @AppStorage private var profileImageData: Data

    init(user: CarePortalUser, logout: @escaping () -> Void) {
        self.user = user
        self.logout = logout
        self._profileImageData = AppStorage(wrappedValue: Data(), "profile.\(user.id).profileImageData")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ProfileHeader(user: user, imageData: profileImageData, selectedPhoto: $selectedPhoto)

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Parent Account")
                            .font(.title3.weight(.bold))

                        InfoRow(title: "Parent Username", value: user.nickname)
                        InfoRow(title: "Parent Email", value: user.email)
                        InfoRow(title: "Account Type", value: "Parent")
                    }
                    .authPanel()

                    Button(role: .destructive, action: logout) {
                        Text("Log Out")
                            .font(.headline.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .padding(20)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Profile")
            .task(id: selectedPhoto) {
                await loadSelectedProfileImage()
            }
        }
    }

    private func loadSelectedProfileImage() async {
        guard let selectedPhoto else { return }

        do {
            if let data = try await selectedPhoto.loadTransferable(type: Data.self) {
                profileImageData = data
            }
        } catch {
            // The picker is user-driven; keeping the current image is the least surprising fallback.
        }
    }
}

struct ProfileHeader: View {
    let user: CarePortalUser
    let imageData: Data
    @Binding var selectedPhoto: PhotosPickerItem?

    private var initials: String {
        user.nickname
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map { String($0).uppercased() }
            .joined()
    }

    var body: some View {
        VStack(spacing: 12) {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.accent.opacity(0.12))
                            .frame(width: 96, height: 96)

                        if let image = profileImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 96, height: 96)
                                .clipShape(Circle())
                        } else {
                            Text(initials)
                                .font(.title.weight(.black))
                                .foregroundStyle(AppTheme.accent)
                        }
                    }

                    Image(systemName: "camera.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(AppTheme.accent)
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .stroke(AppTheme.panel, lineWidth: 3)
                        }
                }
                .accessibilityLabel("Change child profile picture")
            }
            .buttonStyle(.plain)

            VStack(spacing: 6) {
                NavigationLink {
                    BasicInfoView(user: user)
                } label: {
                    HStack(spacing: 8) {
                        Text(user.nickname)
                            .font(.title.weight(.bold))
                            .lineLimit(1)

                        Image(systemName: "chevron.right")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                    .foregroundStyle(AppTheme.text)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open child basic information")

                Text("Parent account for your child's care.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var profileImage: UIImage? {
        guard !imageData.isEmpty else { return nil }
        return UIImage(data: imageData)
    }
}

struct PageHeader: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(AppTheme.accent)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.largeTitle.weight(.bold))

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct HealthMetricRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 28)

            Text(title)
                .fontWeight(.semibold)

            Spacer()

            Text(value)
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.accent)
                .font(.title3.weight(.semibold))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.title2.weight(.bold))

                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 8)
    }
}

struct TrackingRow: View {
    let title: String
    let detail: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color.opacity(0.18))
                .frame(width: 34, height: 34)
                .overlay {
                    Circle()
                        .fill(color)
                        .frame(width: 10, height: 10)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .fontWeight(.semibold)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

struct ProfileTextField: View {
    let title: String
    @Binding var text: String
    var placeholder: String
    var axis: Axis = .horizontal

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.text)

            TextField(placeholder, text: $text, axis: axis)
                .textInputAutocapitalization(.words)
                .padding(12)
                .background(AppTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .lineLimit(axis == .vertical ? 3...5 : 1...1)
        }
    }
}

struct BasicInfoView: View {
    let user: CarePortalUser

    @AppStorage private var fullName: String
    @AppStorage private var birthDate: String
    @AppStorage private var phone: String
    @AppStorage private var address: String
    @AppStorage private var emergencyContact: String
    @AppStorage private var medicalNotes: String

    @State private var isEditing = false
    @State private var draftFullName = ""
    @State private var draftBirthDate = ""
    @State private var draftPhone = ""
    @State private var draftAddress = ""
    @State private var draftEmergencyContact = ""
    @State private var draftMedicalNotes = ""

    init(user: CarePortalUser) {
        self.user = user
        self._fullName = AppStorage(wrappedValue: "", "profile.\(user.id).fullName")
        self._birthDate = AppStorage(wrappedValue: "", "profile.\(user.id).birthDate")
        self._phone = AppStorage(wrappedValue: "", "profile.\(user.id).phone")
        self._address = AppStorage(wrappedValue: "", "profile.\(user.id).address")
        self._emergencyContact = AppStorage(wrappedValue: "", "profile.\(user.id).emergencyContact")
        self._medicalNotes = AppStorage(wrappedValue: "", "profile.\(user.id).medicalNotes")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Parent Account")
                        .font(.headline.weight(.bold))

                    InfoRow(title: "Parent Username", value: user.nickname)
                    InfoRow(title: "Parent Email", value: user.email)
                    InfoRow(title: "Account Type", value: "Parent")
                }
                .authPanel()

                VStack(alignment: .leading, spacing: 16) {
                    Text("Child Profile")
                        .font(.headline.weight(.bold))

                    if isEditing {
                        ProfileTextField(title: "Child Name", text: $draftFullName, placeholder: "Add child's name")
                        ProfileTextField(title: "Date of Birth", text: $draftBirthDate, placeholder: "MM/DD/YYYY")
                        ProfileTextField(title: "Support Needs", text: $draftPhone, placeholder: "Diagnosis, accommodations, or needs", axis: .vertical)
                        ProfileTextField(title: "Home / School Notes", text: $draftAddress, placeholder: "School plan, routines, or home notes", axis: .vertical)
                        ProfileTextField(title: "Emergency Contact", text: $draftEmergencyContact, placeholder: "Name and phone")
                        ProfileTextField(title: "Care Notes", text: $draftMedicalNotes, placeholder: "Allergies, triggers, comforts, medications, or reminders", axis: .vertical)
                    } else {
                        InfoRow(title: "Child Name", value: displayValue(fullName))
                        InfoRow(title: "Date of Birth", value: displayValue(birthDate))
                        InfoRow(title: "Support Needs", value: displayValue(phone))
                        InfoRow(title: "Home / School Notes", value: displayValue(address))
                        InfoRow(title: "Emergency Contact", value: displayValue(emergencyContact))
                        InfoRow(title: "Care Notes", value: displayValue(medicalNotes))
                    }
                }
                .authPanel()
            }
            .padding(20)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isEditing ? saveChanges() : beginEditing()
                } label: {
                    Image(systemName: isEditing ? "checkmark" : "pencil")
                        .font(.headline.weight(.semibold))
                }
                .accessibilityLabel(isEditing ? "Save child information" : "Change child information")
            }
        }
    }

    private func displayValue(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed
    }

    private func beginEditing() {
        draftFullName = fullName
        draftBirthDate = birthDate
        draftPhone = phone
        draftAddress = address
        draftEmergencyContact = emergencyContact
        draftMedicalNotes = medicalNotes
        isEditing = true
    }

    private func saveChanges() {
        fullName = draftFullName.trimmingCharacters(in: .whitespacesAndNewlines)
        birthDate = draftBirthDate.trimmingCharacters(in: .whitespacesAndNewlines)
        phone = draftPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        address = draftAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        emergencyContact = draftEmergencyContact.trimmingCharacters(in: .whitespacesAndNewlines)
        medicalNotes = draftMedicalNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        isEditing = false
        syncChildProfile()
    }

    private func syncChildProfile() {
        let profile = ChildProfileSync(
            fullName: fullName,
            birthDate: birthDate,
            supportNeeds: phone,
            homeSchoolNotes: address,
            emergencyContact: emergencyContact,
            careNotes: medicalNotes
        )

        Task {
            try? await AuthAPI().syncAppData(
                userId: user.id,
                childProfile: profile,
                healthLogs: nil
            )
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}
