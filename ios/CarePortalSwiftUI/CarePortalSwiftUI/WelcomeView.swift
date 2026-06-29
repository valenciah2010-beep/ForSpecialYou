import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct WelcomeView: View {
    let user: CarePortalUser
    let logout: () -> Void
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            BasicHealthView(user: user) {
                selectedTab = 3
            }
                .tabItem {
                    Label(localizedAppString("Health"), systemImage: "heart.text.square")
                }
                .tag(0)

            TherapyTrackingView(user: user)
                .tabItem {
                    Label(localizedAppString("Therapy"), systemImage: "figure.mind.and.body")
                }
                .tag(1)

            NutrientView(user: user)
                .tabItem {
                    Label(localizedAppString("Nutrient"), systemImage: "leaf")
                }
                .tag(2)

            ProfileView(user: user, logout: logout)
                .tabItem {
                    Label(localizedAppString("Profile"), systemImage: "person.crop.circle")
                }
                .tag(3)
        }
        .tint(AppTheme.accent)
    }
}

struct BasicHealthView: View {
    let user: CarePortalUser
    let openProfile: () -> Void
    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.english.rawValue
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
    @AppStorage private var clearedNotificationData: Data
    @AppStorage private var healthInsightCacheData: Data
    @AppStorage private var nutritionGoalsData: Data
    @State private var isQuickLogEditorPresented = false
    @State private var activeLogInput: HealthLogInputTarget?
    @State private var activeSeizureTimer: QuickLogOption?
    @State private var activeMeltdownLog: QuickLogOption?
    @State private var activeStimmingLog: QuickLogOption?
    @State private var activePainLog: QuickLogOption?
    @State private var activeSkinLog: QuickLogOption?
    @State private var activeMedicineLog: QuickLogOption?
    @State private var activeMoodLog: QuickLogOption?
    @State private var activeCyclicVomitingLog: QuickLogOption?
    @State private var activeSleepSnapshot: SleepSnapshotEditorTarget?
    @State private var activeDigestionSnapshot: SnapshotOption?
    @State private var activeNutritionSnapshot: SnapshotOption?
    @State private var draggingQuickLogID: String?
    @State private var isSyncingParentAppData = false
    @State private var healthInsights: [HealthInsight] = []
    @State private var isLoadingHealthInsights = false
    @State private var areHealthInsightsUnavailable = false
    @State private var lastHealthInsightRequestKey: String?
    @State private var isDailyNotificationsPresented = false
    @State private var dailyNotifications: [DailyNotificationItem] = []

    init(user: CarePortalUser, openProfile: @escaping () -> Void = {}) {
        self.user = user
        self.openProfile = openProfile
        self._childName = AppStorage(wrappedValue: "", "profile.\(user.id).fullName")
        self._birthDate = AppStorage(wrappedValue: "", "profile.\(user.id).birthDate")
        self._supportNeeds = AppStorage(wrappedValue: "", "profile.\(user.id).phone")
        self._homeSchoolNotes = AppStorage(wrappedValue: "", "profile.\(user.id).address")
        self._emergencyContact = AppStorage(wrappedValue: "", "profile.\(user.id).emergencyContact")
        self._careNotes = AppStorage(wrappedValue: "", "profile.\(user.id).medicalNotes")
        self._profileImageData = AppStorage(wrappedValue: Data(), "profile.\(user.id).profileImageData")
        self._quickLogSelection = AppStorage(
            wrappedValue: "",
            "health.\(user.id).quickLogSelection"
        )
        self._healthLogData = AppStorage(wrappedValue: Data(), "health.\(user.id).logData")
        self._medicationData = AppStorage(wrappedValue: Data(), "health.\(user.id).medicationData")
        self._medicationCheckData = AppStorage(wrappedValue: Data(), "health.\(user.id).medicationCheckData")
        self._clearedNotificationData = AppStorage(wrappedValue: Data(), "health.\(user.id).clearedNotificationData")
        self._healthInsightCacheData = AppStorage(wrappedValue: Data(), "health.\(user.id).insightCacheData")
        self._nutritionGoalsData = AppStorage(wrappedValue: Data(), "nutrient.\(user.id).nutritionGoalsData")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                    HealthDashboardHeader(
                        childName: displayChildName,
                        parentName: user.nickname,
                        imageData: profileImageData,
                        onProfileTap: openProfile,
                        onNotificationTap: showDailyNotifications
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

                                Text(localizedAppString("History"))
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(AppTheme.accent)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(localizedAppString("Open quick-log history"))

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
                        .accessibilityLabel(localizedAppString("Choose quick-log buttons"))
                    }

                    if selectedQuickLogs.isEmpty {
                        QuickLogEmptySelectionCard {
                            isQuickLogEditorPresented = true
                        }
                    } else {
                        LazyVGrid(columns: quickLogColumns, spacing: 10) {
                            ForEach(selectedQuickLogs) { option in
                                QuickLogCard(option: option) {
                                    if option.id == "seizure" {
                                        activeSeizureTimer = option
                                    } else if option.id == "meltdown" {
                                        activeMeltdownLog = option
                                    } else if option.id == "stimming" {
                                        activeStimmingLog = option
                                    } else if option.id == "pain" {
                                        activePainLog = option
                                    } else if option.id == "skin" {
                                        activeSkinLog = option
                                    } else if option.id == "medsFood" {
                                        activeMedicineLog = option
                                    } else if option.id == "mood" {
                                        activeMoodLog = option
                                    } else if option.id == "cyclicVomiting" {
                                        activeCyclicVomitingLog = option
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

                                Text(localizedAppString("History"))
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(AppTheme.accent)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(localizedAppString("Open daily snapshot history"))

                        Spacer()
                    }

                    LazyVGrid(columns: snapshotColumns, spacing: 10) {
                        ForEach(SnapshotOption.all) { option in
                            let snapshotSummary = todaysSnapshotSummary(for: option)

                            SnapshotCard(
                                option: option,
                                displayValue: snapshotSummary.value,
                                displayDetail: snapshotSummary.detail,
                                displayIcon: snapshotSummary.icon,
                                sleepDurationText: option.id == "sleep" && snapshotSummary.isLoggedToday ? snapshotSummary.value : nil,
                                isLoggedToday: snapshotSummary.isLoggedToday
                            ) {
                                if option.id == "sleep" {
                                    activeSleepSnapshot = SleepSnapshotEditorTarget(
                                        option: option,
                                        existingEntry: todaysSleepEntry
                                    )
                                } else if option.id == "digestion" {
                                    activeDigestionSnapshot = option
                                } else if option.id == "nutrition" {
                                    activeNutritionSnapshot = option
                                } else if option.id == "mood",
                                          let moodOption = QuickLogOption.option(id: "mood") {
                                    activeMoodLog = moodOption
                                } else {
                                    activeLogInput = .snapshot(option)
                                }
                            }
                        }
                    }

                    DashboardSectionTitle("Insights & Alerts")

                    insightsAndAlertsSection
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(localizedAppString("Dashboard"))
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
            .sheet(item: $activeDigestionSnapshot) { option in
                DigestionSnapshotSheet(option: option) { entry in
                    saveLogEntry(entry)
                }
            }
            .sheet(item: $activeNutritionSnapshot) { option in
                NutritionSnapshotSheet(userID: user.id, option: option) { entry in
                    saveNutritionEntry(entry)
                }
            }
            .sheet(item: $activeSeizureTimer) { option in
                SeizureTimerSheet(option: option, initialSeizureType: mostRecentSeizureType) { entry in
                    saveLogEntry(entry)
                }
            }
            .sheet(item: $activeMeltdownLog) { option in
                MeltdownLogEntrySheet(option: option) { entry in
                    saveLogEntry(entry)
                }
            }
            .sheet(item: $activeStimmingLog) { option in
                StimmingTicsLogEntrySheet(option: option) { entry in
                    saveLogEntry(entry)
                }
            }
            .sheet(item: $activePainLog) { option in
                PainLogEntrySheet(option: option) { entry in
                    saveLogEntry(entry)
                }
            }
            .sheet(item: $activeSkinLog) { option in
                SkinLogEntrySheet(option: option) { entry in
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
            .sheet(item: $activeMoodLog) { option in
                MoodLogSheet(option: option) { entry in
                    saveLogEntry(entry)
                }
            }
            .sheet(item: $activeCyclicVomitingLog) { option in
                CyclicVomitingLogSheet(option: option, userID: user.id) { entry in
                    saveLogEntry(entry)
                }
            }
            .sheet(isPresented: $isDailyNotificationsPresented) {
                DailyNotificationsSheet(
                    notifications: dailyNotifications,
                    onClear: clearDailyNotification,
                    onMarkTaken: markNotificationMedicationTaken
                )
                .presentationDetents([.medium, .large])
            }
            .onAppear {
                syncParentAppDataIfLocalDataExists()
                MedicationReminderScheduler.reschedule(medications: medications)
            }
            .task(id: healthInsightRefreshKey) {
                await refreshHealthInsightsIfNeeded()
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
        return orderedKnownIDs
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

    private func todaysSnapshotSummary(for option: SnapshotOption) -> SnapshotCardDisplay {
        if option.id == "nutrition", let display = nutritionGoalsSnapshotDisplay {
            return display
        }

        guard let entry = option.id == "mood" ? latestTodayMoodEntry : latestTodaySnapshotEntry(for: option.id) else {
            return SnapshotCardDisplay(value: "--", detail: "--", isLoggedToday: false)
        }

        if option.id == "sleep" {
            let summary = sleepSummary(from: entry)
            return SnapshotCardDisplay(
                value: summary.durationText,
                detail: summary.detailText,
                isLoggedToday: true
            )
        }

        let value = entry.value.trimmingCharacters(in: .whitespacesAndNewlines)
        let comments = entry.comments.trimmingCharacters(in: .whitespacesAndNewlines)
        let firstValueLine = value
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }

        return SnapshotCardDisplay(
            value: firstValueLine ?? localizedAppString("Saved"),
            detail: comments.isEmpty ? localizedAppString("Saved today") : comments,
            isLoggedToday: true
        )
    }

    private var nutritionGoalsSnapshotDisplay: SnapshotCardDisplay? {
        guard !nutritionGoalsData.isEmpty,
              var goals = try? JSONDecoder().decode(NutritionGoals.self, from: nutritionGoalsData),
              !goals.isEmpty else {
            return nil
        }

        let previousDateKey = goals.consumedDateKey
        goals.resetDailyProgressIfNeeded()
        if previousDateKey != goals.consumedDateKey,
           let data = try? JSONEncoder().encode(goals) {
            nutritionGoalsData = data
        }

        let lines = goals.summaryLines
        let primaryLine = lines.first ?? localizedAppString("Nutrition goals saved")
        let secondaryLine = lines.dropFirst().first ?? localizedAppString("Nutrition goals saved")

        return SnapshotCardDisplay(
            value: localizedSavedAIText(primaryLine),
            detail: localizedSavedAIText(secondaryLine),
            icon: goals.hasConsumedNutritionToday ? "fork.knife" : "checkmark.circle.fill",
            isLoggedToday: true
        )
    }

    private func latestTodaySnapshotEntry(for optionID: String) -> HealthLogEntry? {
        logEntries
            .filter({ $0.type == .snapshot && $0.categoryID == optionID })
            .filter { Calendar.current.isDateInToday($0.timestamp) }
            .sorted(by: { $0.timestamp > $1.timestamp })
            .first
    }

    private var latestTodayMoodEntry: HealthLogEntry? {
        logEntries
            .filter({ $0.type == .quickLog && $0.categoryID == "mood" })
            .filter { Calendar.current.isDateInToday($0.timestamp) }
            .sorted(by: { $0.timestamp > $1.timestamp })
            .first
    }

    private func sleepSummary(from entry: HealthLogEntry) -> SleepSnapshotSummary {
        let parts = entry.value
            .components(separatedBy: "·")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard let duration = parts.first else {
            return SleepSnapshotSummary(durationText: "Saved", detailText: "Sleep logged")
        }

        let detail = parts.dropFirst().map(localizedSleepDetailPart).joined(separator: " · ")
        return SleepSnapshotSummary(
            durationText: duration,
            detailText: detail.isEmpty ? localizedAppString("Sleep logged") : detail
        )
    }

    private func localizedSleepDetailPart(_ part: String) -> String {
        let trimmed = part.trimmingCharacters(in: .whitespacesAndNewlines)
        if ["Restless", "Normal", "Deep"].contains(trimmed) {
            return localizedAppString(trimmed)
        }

        if trimmed.localizedCaseInsensitiveContains("wake-up") {
            let countText = trimmed.components(separatedBy: " ").first ?? ""
            return "\(countText) \(localizedAppString(countText == "1" ? "wake-up" : "wake-ups"))"
        }

        return localizedAppString(trimmed)
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

    private var todaysLogEntries: [HealthLogEntry] {
        logEntries.filter { Calendar.current.isDateInToday($0.timestamp) }
    }

    private var completedQuickLogIDsToday: Set<String> {
        Set(
            todaysLogEntries
                .filter { $0.type == .quickLog }
                .map(\.categoryID)
        )
    }

    private var completedSnapshotIDsToday: Set<String> {
        var ids = Set(
            todaysLogEntries
                .filter { $0.type == .snapshot }
                .map(\.categoryID)
        )

        if completedQuickLogIDsToday.contains("mood") {
            ids.insert("mood")
        }

        return ids
    }

    private var isDailyHealthComplete: Bool {
        !selectedQuickLogs.isEmpty
            && selectedQuickLogs.allSatisfy { completedQuickLogIDsToday.contains($0.id) }
            && SnapshotOption.all.allSatisfy { completedSnapshotIDsToday.contains($0.id) }
    }

    private var healthInsightRefreshKey: String {
        "\(healthInsightDateKey)-\(isDailyHealthComplete)"
    }

    private var healthInsightDateKey: String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }

    @ViewBuilder
    private var insightsAndAlertsSection: some View {
        VStack(spacing: 10) {
            if !isDailyHealthComplete {
                InsightCard(
                    title: "Notice",
                    message: "Complete all quick-log and daily snapshot buttons to get AI insights and alerts."
                )
            } else if isLoadingHealthInsights {
                InsightCard(
                    title: "AI",
                    message: "Reviewing today's completed logs for insights and alerts."
                )
            } else if areHealthInsightsUnavailable {
                InsightUnavailableIndicator()
            } else if healthInsights.isEmpty {
                InsightCard(
                    title: "AI",
                    message: "AI insights and alerts will appear after today's completed logs are reviewed."
                )
            } else {
                ForEach(healthInsights) { insight in
                    InsightCard(title: insight.title, message: insight.message)
                }
            }
        }
    }

    private func showDailyNotifications() {
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            let calendar = Calendar.current
            let clearedIDs = clearedDailyNotificationIDs
            let deliveredItems = notifications
                .filter { calendar.isDateInToday($0.date) }
                .map { notification in
                    let isMedicineReminder = isMedicationReminderNotification(notification)
                    let checklistID = medicationChecklistID(for: notification)
                    return DailyNotificationItem(
                        notificationIdentifier: notification.request.identifier,
                        date: notification.date,
                        title: notification.request.content.title,
                        body: notification.request.content.body,
                        isMedicineReminder: isMedicineReminder,
                        medicationChecklistID: checklistID
                    )
                }
                .filter { !clearedIDs.contains($0.clearKey) }

            let deliveredChecklistIDs = Set(deliveredItems.compactMap(\.medicationChecklistID))
            let scheduledItems = scheduledMedicineNotificationItems()
                .filter { !clearedIDs.contains($0.clearKey) }
                .filter { !deliveredChecklistIDs.contains($0.medicationChecklistID ?? "") }

            let items = (deliveredItems + scheduledItems)
                .sorted { $0.date > $1.date }

            DispatchQueue.main.async {
                dailyNotifications = items
                isDailyNotificationsPresented = true
            }
        }
    }

    private func clearDailyNotification(_ notification: DailyNotificationItem) {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [notification.notificationIdentifier])
        saveClearedDailyNotificationID(notification.clearKey)
        dailyNotifications.removeAll { $0.id == notification.id }
    }

    private func markNotificationMedicationTaken(_ notification: DailyNotificationItem) {
        guard let checklistID = notification.medicationChecklistID else {
            clearDailyNotification(notification)
            return
        }

        var updatedState = medicationCheckState
        if updatedState.dateKey != MedicationCheckState.todayKey {
            updatedState = MedicationCheckState.today()
        }

        if !updatedState.checkedIDs.contains(checklistID) {
            updatedState.checkedIDs.append(checklistID)
            updatedState.checkedIDs.sort()
        }

        saveMedicationCheckState(updatedState)
        clearDailyNotification(notification)
    }

    private func medicationChecklistID(for notification: UNNotification) -> String? {
        if let checklistID = notification.request.content.userInfo["medicationChecklistID"] as? String {
            return checklistID
        }

        guard isMedicationReminderNotification(notification) else {
            return nil
        }

        let body = notification.request.content.body.lowercased()
        let calendar = Calendar.current
        let reminderMinutes = calendar.component(.hour, from: notification.date) * 60
            + calendar.component(.minute, from: notification.date)
        let candidates = todayMedicationChecklistRows.filter { row in
            abs(row.sortMinutes - reminderMinutes) <= 2
        }

        return candidates.first { row in
            let name = row.medication.displayName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let dose = row.dose.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let matchesName = name.isEmpty || body.contains(name)
            let matchesDose = dose.isEmpty || body.contains(dose)
            return matchesName && matchesDose
        }?.id ?? candidates.first?.id
    }

    private func isMedicationReminderNotification(_ notification: UNNotification) -> Bool {
        let userInfo = notification.request.content.userInfo
        if let kind = userInfo["kind"] as? String, kind == "medicineReminder" {
            return true
        }

        let title = notification.request.content.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let knownTitles = [
            "Medicine Reminder",
            localizedAppString("Medicine Reminder", languageCode: "en"),
            localizedAppString("Medicine Reminder", languageCode: "zh-Hans")
        ]
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }

        if knownTitles.contains(title) {
            return true
        }

        let body = notification.request.content.body.lowercased()
        return body.contains("time to take")
    }

    private var clearedDailyNotificationIDs: Set<String> {
        guard !clearedNotificationData.isEmpty,
              let savedState = try? JSONDecoder().decode(DailyNotificationDismissState.self, from: clearedNotificationData),
              savedState.dateKey == MedicationCheckState.todayKey else {
            return []
        }

        return Set(savedState.clearedIDs)
    }

    private func saveClearedDailyNotificationID(_ id: String) {
        guard !id.isEmpty else { return }

        var state = DailyNotificationDismissState(dateKey: MedicationCheckState.todayKey, clearedIDs: Array(clearedDailyNotificationIDs))
        if !state.clearedIDs.contains(id) {
            state.clearedIDs.append(id)
            state.clearedIDs.sort()
        }

        if let encoded = try? JSONEncoder().encode(state) {
            clearedNotificationData = encoded
        }
    }

    private func scheduledMedicineNotificationItems(calendar: Calendar = .current) -> [DailyNotificationItem] {
        let currentMinutes = calendar.component(.hour, from: Date()) * 60 + calendar.component(.minute, from: Date())
        let checkedIDs = medicationCheckState.dateKey == MedicationCheckState.todayKey
            ? Set(medicationCheckState.checkedIDs)
            : []

        return todayMedicationChecklistRows
            .filter { $0.sortMinutes <= currentMinutes }
            .filter { !checkedIDs.contains($0.id) }
            .map { row in
                DailyNotificationItem(
                    notificationIdentifier: "scheduled-medicine.\(MedicationCheckState.todayKey).\(row.id)",
                    date: dateForToday(minutes: row.sortMinutes, calendar: calendar),
                    title: localizedAppString("Medicine Reminder"),
                    body: medicineReminderBody(for: row),
                    isMedicineReminder: true,
                    medicationChecklistID: row.id
                )
            }
    }

    private func dateForToday(minutes: Int, calendar: Calendar = .current) -> Date {
        calendar.date(
            bySettingHour: max(0, min(23, minutes / 60)),
            minute: max(0, min(59, minutes % 60)),
            second: 0,
            of: Date()
        ) ?? Date()
    }

    private func medicineReminderBody(for row: MedicationChecklistItem) -> String {
        let name = row.medication.displayName.isEmpty ? localizedAppString("medicine") : row.medication.displayName
        let dose = row.dose.trimmingCharacters(in: .whitespacesAndNewlines)
        return dose.isEmpty ? "Time to take \(name)." : "Time to take \(name) \(dose)."
    }

    private var todayMedicationChecklistRows: [MedicationChecklistItem] {
        let today = MedicationWeekday.today()

        return medications.flatMap { medication -> [MedicationChecklistItem] in
            switch medication.mode {
            case .daily:
                return medication.dailyTimes.map { time in
                    medicationChecklistItem(for: medication, day: nil, time: time)
                }
            case .intervalDays:
                guard isMedicationDueToday(medication) else { return [] }
                return medication.dailyTimes.map { time in
                    medicationChecklistItem(for: medication, day: nil, time: time)
                }
            case .weekly:
                guard medication.weeklyDays.contains(today) else { return [] }
                return medication.weeklyTimes.map { time in
                    medicationChecklistItem(for: medication, day: today, time: time)
                }
            }
        }
        .sorted { first, second in
            if first.sortMinutes == second.sortMinutes {
                return first.medication.displayName.localizedCaseInsensitiveCompare(second.medication.displayName) == .orderedAscending
            }

            return first.sortMinutes < second.sortMinutes
        }
    }

    private func medicationChecklistItem(
        for medication: MedicationSchedule,
        day: MedicationWeekday?,
        time: MedicationDayTime
    ) -> MedicationChecklistItem {
        MedicationChecklistItem(
            id: MedicationChecklistIdentifier.id(for: medication, day: day, time: time),
            medication: medication,
            time: time,
            dose: medication.dose(for: day, time: time),
            timeText: medication.clockTimeText(for: day, time: time),
            sortMinutes: medication.clockTimeMinutes(for: day, time: time)
        )
    }

    private func isMedicationDueToday(_ medication: MedicationSchedule, calendar: Calendar = .current) -> Bool {
        let interval = max(1, medication.intervalDays)
        let start = calendar.startOfDay(for: medication.startDate)
        let today = calendar.startOfDay(for: Date())
        guard let days = calendar.dateComponents([.day], from: start, to: today).day, days >= 0 else {
            return false
        }

        return days % interval == 0
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

    @MainActor
    private func refreshHealthInsightsIfNeeded() async {
        guard isDailyHealthComplete else {
            healthInsights = []
            areHealthInsightsUnavailable = false
            lastHealthInsightRequestKey = nil
            return
        }

        if let cachedInsights = todaysHealthInsightCache {
            let dailyInsights = oneDailyHealthInsight(from: cachedInsights.insights)
            healthInsights = dailyInsights
            areHealthInsightsUnavailable = cachedInsights.isUnavailable
            lastHealthInsightRequestKey = healthInsightRefreshKey
            if cachedInsights.dateKey != healthInsightDateKey || cachedInsights.insights.count != dailyInsights.count {
                saveHealthInsightCache(
                    HealthInsightDailyCache(
                        dateKey: healthInsightDateKey,
                        insights: dailyInsights,
                        isUnavailable: cachedInsights.isUnavailable
                    )
                )
            }
            return
        }

        let requestKey = healthInsightRefreshKey
        guard lastHealthInsightRequestKey != requestKey else { return }

        isLoadingHealthInsights = true
        areHealthInsightsUnavailable = false

        do {
            let insights = oneDailyHealthInsight(
                from: try await AuthAPI().healthInsights(
                    childName: displayChildName,
                    quickLogTitles: selectedQuickLogs.map { localizedAppString($0.title, languageCode: languageCode) },
                    snapshotTitles: SnapshotOption.all.map { localizedAppString($0.title, languageCode: languageCode) },
                    logs: todaysLogEntries.sorted { $0.timestamp < $1.timestamp },
                    language: AppLanguage(code: languageCode).apiName
                )
            )
            healthInsights = insights
            lastHealthInsightRequestKey = requestKey
            areHealthInsightsUnavailable = false
            saveHealthInsightCache(
                HealthInsightDailyCache(
                    dateKey: healthInsightDateKey,
                    insights: insights,
                    isUnavailable: false
                )
            )
        } catch {
            healthInsights = []
            areHealthInsightsUnavailable = true
            lastHealthInsightRequestKey = requestKey
            saveHealthInsightCache(
                HealthInsightDailyCache(
                    dateKey: healthInsightDateKey,
                    insights: [],
                    isUnavailable: true
                )
            )
            print("Health insights failed: \(error.localizedDescription)")
        }

        isLoadingHealthInsights = false
    }

    private var todaysHealthInsightCache: HealthInsightDailyCache? {
        guard !healthInsightCacheData.isEmpty,
              let cache = try? JSONDecoder().decode(HealthInsightDailyCache.self, from: healthInsightCacheData) else {
            return nil
        }

        let legacyLanguageKeys = AppLanguage.allCases.map { "\(healthInsightDateKey)-\($0.rawValue)" }
        return cache.dateKey == healthInsightDateKey || legacyLanguageKeys.contains(cache.dateKey) ? cache : nil
    }

    private func oneDailyHealthInsight(from insights: [HealthInsight]) -> [HealthInsight] {
        guard let firstInsight = insights.first else { return [] }
        return [
            HealthInsight(
                id: firstInsight.id,
                title: firstInsight.title,
                message: shortenedHealthInsightMessage(firstInsight.message)
            )
        ]
    }

    private func shortenedHealthInsightMessage(_ message: String) -> String {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        let sentenceEnds = CharacterSet(charactersIn: ".!?。！？")
        if let endIndex = trimmed.rangeOfCharacter(from: sentenceEnds)?.upperBound {
            return String(trimmed[..<endIndex])
        }

        guard trimmed.count > 140 else { return trimmed }
        return String(trimmed.prefix(137)).trimmingCharacters(in: .whitespacesAndNewlines) + "..."
    }

    private func saveHealthInsightCache(_ cache: HealthInsightDailyCache) {
        if let data = try? JSONEncoder().encode(cache) {
            healthInsightCacheData = data
        }
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

    private func saveNutritionEntry(_ entry: HealthLogEntry) {
        var updatedEntries = logEntries.filter { savedEntry in
            !(savedEntry.type == .snapshot
              && savedEntry.categoryID == "nutrition"
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
            MedicationReminderScheduler.reschedule(medications: sortedMedications)
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
            await syncParentAppDataOnce(
                userId: user.id,
                childProfile: profileToSync,
                healthLogs: logsToSync,
                retryOnFailure: true
            )
        }
    }

    private func syncParentAppDataIfLocalDataExists() {
        let hasProfileData = [
            childName,
            birthDate,
            supportNeeds,
            homeSchoolNotes,
            emergencyContact,
            careNotes
        ]
        .contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        guard hasProfileData || !logEntries.isEmpty else { return }
        syncParentAppData()
    }

    @MainActor
    private func syncParentAppDataOnce(
        userId: Int,
        childProfile: ChildProfileSync,
        healthLogs: [HealthLogEntry],
        retryOnFailure: Bool
    ) async {
        guard !isSyncingParentAppData else { return }
        isSyncingParentAppData = true
        defer { isSyncingParentAppData = false }

        let attemptCount = retryOnFailure ? 2 : 1

        for attempt in 1...attemptCount {
            do {
                try await AuthAPI().syncAppData(
                    userId: userId,
                    childProfile: childProfile,
                    healthLogs: healthLogs
                )
                print("Parent app data synced for user \(userId). Logs: \(healthLogs.count)")
                return
            } catch {
                print("Parent app data sync failed for user \(userId) on attempt \(attempt): \(error.localizedDescription)")

                if attempt < attemptCount {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                }
            }
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
    let onProfileTap: () -> Void
    let onNotificationTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onProfileTap) {
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
            }
            .buttonStyle(.plain)
            .accessibilityLabel(localizedAppString("Open profile"))

            VStack(alignment: .leading, spacing: 3) {
                Text(String(format: localizedAppString("%@'s Day"), childName))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.text)
                    .lineLimit(1)

                Text(String(format: localizedAppString("Monitored by %@"), parentName))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onNotificationTap) {
                Image(systemName: "bell.badge")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppTheme.text)
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(localizedAppString("Open notifications"))
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

struct DailyNotificationItem: Identifiable {
    let id = UUID()
    let notificationIdentifier: String
    let date: Date
    let title: String
    let body: String
    let isMedicineReminder: Bool
    let medicationChecklistID: String?

    var canMarkTaken: Bool {
        isMedicineReminder
    }

    var clearKey: String {
        medicationChecklistID ?? notificationIdentifier
    }
}

struct DailyNotificationsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let notifications: [DailyNotificationItem]
    let onClear: (DailyNotificationItem) -> Void
    let onMarkTaken: (DailyNotificationItem) -> Void

    var body: some View {
        NavigationStack {
            List {
                if notifications.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "bell.slash.fill")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(AppTheme.accent)

                        Text(localizedAppString("No notifications received today."))
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(28)
                    .background(AppTheme.panel)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .listRowInsets(EdgeInsets(top: 18, leading: 18, bottom: 18, trailing: 18))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(notifications) { notification in
                        DailyNotificationRow(notification: notification)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button {
                                    onClear(notification)
                                } label: {
                                    Label(localizedAppString("Clear"), systemImage: "xmark.circle.fill")
                                }
                                .tint(.red)

                                if notification.canMarkTaken {
                                    Button {
                                        onMarkTaken(notification)
                                    } label: {
                                        Label(localizedAppString("Done"), systemImage: "checkmark.circle.fill")
                                    }
                                    .tint(AppTheme.accent)
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 6, leading: 18, bottom: 6, trailing: 18))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(localizedAppString("Notifications Today"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(localizedAppString("Done")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DailyNotificationRow: View {
    let notification: DailyNotificationItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(notification.title.isEmpty ? localizedAppString("Notification") : localizedAppString(notification.title))
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.text)

                Spacer()

                Text(localizedDateString(notification.date, dateStyle: .none, timeStyle: .short))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }

            if !notification.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(localizedAppString(notification.body))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(AppTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct DashboardSectionTitle: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(LocalizedStringKey(title))
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
        QuickLogOption(id: "mood", title: "Mood", icon: "face.smiling", tint: Color(red: 0.95, green: 0.52, blue: 0.61)),
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

    static let defaultSelectionString = "seizure,meltdown,mood,cyclicVomiting,medsFood"
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
    let imageData: Data?

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case categoryID
        case title
        case timestamp
        case severity
        case value
        case comments
        case imageData
    }

    init(
        id: UUID,
        type: LogType,
        categoryID: String,
        title: String,
        timestamp: Date,
        severity: Int,
        value: String,
        comments: String,
        imageData: Data? = nil
    ) {
        self.id = id
        self.type = type
        self.categoryID = categoryID
        self.title = title
        self.timestamp = timestamp
        self.severity = severity
        self.value = value
        self.comments = comments
        self.imageData = imageData
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(LogType.self, forKey: .type)
        categoryID = try container.decode(String.self, forKey: .categoryID)
        title = try container.decode(String.self, forKey: .title)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        severity = try container.decode(Int.self, forKey: .severity)
        value = try container.decode(String.self, forKey: .value)
        comments = try container.decode(String.self, forKey: .comments)
        imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
    }
}

struct CyclicVomitingBackgroundData: Codable {
    var familyHistory: [String] = []
    var surgicalHistory: [String] = []
    var otherSurgery: String = ""
    var onsetYear: String = ""
    var onsetMonth: String = ""
    var comorbidities: [String] = []
    var metabolismName: String = ""
    var otherComorbidity: String = ""
    var hospitalizedAtBeijingHospital: Bool?
    var currentMedications: [String] = []
    var otherCurrentMedication: String = ""
    var hadAdverseDrugReaction: Bool?
    var adverseDrugReactionDetails: String = ""
    var pastMedications: [String] = []
    var otherPastMedication: String = ""
}

struct CyclicVomitingProgressData: Codable {
    var startTime = Date()
    var endTime = Date()
    var hospitalized: Bool?
    var triggers: [String] = []
    var otherTriggers = ""
    var beforeSymptoms: [String] = []
    var otherBeforeSymptoms = ""
    var duringSymptoms: [String] = []
    var otherDuringSymptoms = ""
    var recoverySymptoms: [String] = []
    var otherRecoverySymptoms = ""
    var vomitingActsPerDay = 1
    var medications: [String] = []
    var otherMedication = ""
}

struct CyclicVomitingPatternsData: Codable {
    var episodesPastYear = ""
    var episodeInterval = ""
    var episodeDuration = ""
    var historicalTriggers: [String] = []
    var otherHistoricalTriggers = ""
    var prodromalSymptoms: [String] = []
    var otherProdromalSymptoms = ""
    var episodeSymptoms: [String] = []
    var otherEpisodeSymptoms = ""
    var postdromalSymptoms: [String] = []
    var otherPostdromalSymptoms = ""
    var heightCm = ""
    var heightUnit: String? = "cm"
    var weightKg = ""
    var weightUnit: String? = "Kg"
    var qualityOfLifeAgeGroup = ""
    var qualityOfLifeResponses: [String: Int] = [:]

    enum CodingKeys: String, CodingKey {
        case episodesPastYear
        case episodeInterval
        case episodeDuration
        case historicalTriggers
        case otherHistoricalTriggers
        case prodromalSymptoms
        case otherProdromalSymptoms
        case episodeSymptoms
        case otherEpisodeSymptoms
        case postdromalSymptoms
        case otherPostdromalSymptoms
        case heightCm
        case heightUnit
        case weightKg
        case weightUnit
        case qualityOfLifeAgeGroup
        case qualityOfLifeResponses
    }

    init(
        episodesPastYear: String = "",
        episodeInterval: String = "",
        episodeDuration: String = "",
        historicalTriggers: [String] = [],
        otherHistoricalTriggers: String = "",
        prodromalSymptoms: [String] = [],
        otherProdromalSymptoms: String = "",
        episodeSymptoms: [String] = [],
        otherEpisodeSymptoms: String = "",
        postdromalSymptoms: [String] = [],
        otherPostdromalSymptoms: String = "",
        heightCm: String = "",
        heightUnit: String? = "cm",
        weightKg: String = "",
        weightUnit: String? = "Kg",
        qualityOfLifeAgeGroup: String = "",
        qualityOfLifeResponses: [String: Int] = [:]
    ) {
        self.episodesPastYear = episodesPastYear
        self.episodeInterval = episodeInterval
        self.episodeDuration = episodeDuration
        self.historicalTriggers = historicalTriggers
        self.otherHistoricalTriggers = otherHistoricalTriggers
        self.prodromalSymptoms = prodromalSymptoms
        self.otherProdromalSymptoms = otherProdromalSymptoms
        self.episodeSymptoms = episodeSymptoms
        self.otherEpisodeSymptoms = otherEpisodeSymptoms
        self.postdromalSymptoms = postdromalSymptoms
        self.otherPostdromalSymptoms = otherPostdromalSymptoms
        self.heightCm = heightCm
        self.heightUnit = heightUnit
        self.weightKg = weightKg
        self.weightUnit = weightUnit
        self.qualityOfLifeAgeGroup = qualityOfLifeAgeGroup
        self.qualityOfLifeResponses = qualityOfLifeResponses
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        episodesPastYear = try container.decodeIfPresent(String.self, forKey: .episodesPastYear) ?? ""
        episodeInterval = try container.decodeIfPresent(String.self, forKey: .episodeInterval) ?? ""
        episodeDuration = try container.decodeIfPresent(String.self, forKey: .episodeDuration) ?? ""
        historicalTriggers = try container.decodeIfPresent([String].self, forKey: .historicalTriggers) ?? []
        otherHistoricalTriggers = try container.decodeIfPresent(String.self, forKey: .otherHistoricalTriggers) ?? ""
        prodromalSymptoms = try container.decodeIfPresent([String].self, forKey: .prodromalSymptoms) ?? []
        otherProdromalSymptoms = try container.decodeIfPresent(String.self, forKey: .otherProdromalSymptoms) ?? ""
        episodeSymptoms = try container.decodeIfPresent([String].self, forKey: .episodeSymptoms) ?? []
        otherEpisodeSymptoms = try container.decodeIfPresent(String.self, forKey: .otherEpisodeSymptoms) ?? ""
        postdromalSymptoms = try container.decodeIfPresent([String].self, forKey: .postdromalSymptoms) ?? []
        otherPostdromalSymptoms = try container.decodeIfPresent(String.self, forKey: .otherPostdromalSymptoms) ?? ""
        heightCm = try container.decodeIfPresent(String.self, forKey: .heightCm) ?? ""
        heightUnit = try container.decodeIfPresent(String.self, forKey: .heightUnit) ?? "cm"
        weightKg = try container.decodeIfPresent(String.self, forKey: .weightKg) ?? ""
        weightUnit = try container.decodeIfPresent(String.self, forKey: .weightUnit) ?? "Kg"
        qualityOfLifeAgeGroup = try container.decodeIfPresent(String.self, forKey: .qualityOfLifeAgeGroup) ?? ""
        qualityOfLifeResponses = try container.decodeIfPresent([String: Int].self, forKey: .qualityOfLifeResponses) ?? [:]
    }
}

struct SleepSnapshotSummary {
    let durationText: String
    let detailText: String
}

struct SnapshotCardDisplay {
    let value: String
    let detail: String
    var icon: String? = nil
    let isLoggedToday: Bool
}

struct HealthInsightDailyCache: Codable {
    let dateKey: String
    let insights: [HealthInsight]
    let isUnavailable: Bool
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
            return "Dose 1"
        case .noon:
            return "Dose 2"
        case .evening:
            return "Dose 3"
        }
    }

    var defaultClockTime: String {
        switch self {
        case .morning:
            return "08:00"
        case .noon:
            return "12:00"
        case .evening:
            return "18:00"
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

    static func from(date: Date, calendar: Calendar = .current) -> MedicationWeekday? {
        let weekday = calendar.component(.weekday, from: date)
        return allCases.first { $0.calendarWeekday == weekday }
    }
}

enum MedicationScheduleMode: String, CaseIterable, Codable, Identifiable {
    case daily
    case intervalDays
    case weekly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily:
            return "Daily"
        case .intervalDays:
            return "Every X days"
        case .weekly:
            return "Certain days of the week"
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
    var clockTimes: [String: String]
    var medicineType: String
    var amount: String
    var unit: String
    var duration: String
    var startDate: Date
    var intervalDays: Int
    var prescribingDoctor: String
    var instructions: String

    static func empty() -> MedicationSchedule {
        MedicationSchedule(
            id: UUID(),
            name: "",
            nickname: "",
            mode: .daily,
            dailyTimes: [],
            weeklyDays: [],
            weeklyTimes: [],
            doses: [:],
            clockTimes: [:],
            medicineType: "Round Tablet",
            amount: "",
            unit: "Tablet(s)",
            duration: "",
            startDate: Date(),
            intervalDays: 2,
            prescribingDoctor: "",
            instructions: ""
        )
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case nickname
        case mode
        case dailyTimes
        case weeklyDays
        case weeklyTimes
        case doses
        case clockTimes
        case medicineType
        case amount
        case unit
        case duration
        case startDate
        case intervalDays
        case prescribingDoctor
        case instructions
    }

    init(
        id: UUID,
        name: String,
        nickname: String,
        mode: MedicationScheduleMode,
        dailyTimes: [MedicationDayTime],
        weeklyDays: [MedicationWeekday],
        weeklyTimes: [MedicationDayTime],
        doses: [String: String],
        clockTimes: [String: String],
        medicineType: String,
        amount: String,
        unit: String,
        duration: String,
        startDate: Date,
        intervalDays: Int,
        prescribingDoctor: String,
        instructions: String
    ) {
        self.id = id
        self.name = name
        self.nickname = nickname
        self.mode = mode
        self.dailyTimes = dailyTimes
        self.weeklyDays = weeklyDays
        self.weeklyTimes = weeklyTimes
        self.doses = doses
        self.clockTimes = clockTimes
        self.medicineType = medicineType
        self.amount = amount
        self.unit = unit
        self.duration = duration
        self.startDate = startDate
        self.intervalDays = intervalDays
        self.prescribingDoctor = prescribingDoctor
        self.instructions = instructions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        nickname = try container.decode(String.self, forKey: .nickname)
        mode = try container.decode(MedicationScheduleMode.self, forKey: .mode)
        dailyTimes = try container.decode([MedicationDayTime].self, forKey: .dailyTimes)
        weeklyDays = try container.decode([MedicationWeekday].self, forKey: .weeklyDays)
        weeklyTimes = try container.decode([MedicationDayTime].self, forKey: .weeklyTimes)
        doses = try container.decode([String: String].self, forKey: .doses)
        clockTimes = try container.decodeIfPresent([String: String].self, forKey: .clockTimes) ?? [:]
        medicineType = try container.decodeIfPresent(String.self, forKey: .medicineType) ?? "Round Tablet"
        amount = try container.decodeIfPresent(String.self, forKey: .amount) ?? ""
        unit = try container.decodeIfPresent(String.self, forKey: .unit) ?? "Tablet(s)"
        duration = try container.decodeIfPresent(String.self, forKey: .duration) ?? ""
        startDate = try container.decodeIfPresent(Date.self, forKey: .startDate) ?? Date()
        intervalDays = try container.decodeIfPresent(Int.self, forKey: .intervalDays) ?? 2
        prescribingDoctor = try container.decodeIfPresent(String.self, forKey: .prescribingDoctor) ?? ""
        instructions = try container.decodeIfPresent(String.self, forKey: .instructions) ?? ""
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

    func clockTime(for day: MedicationWeekday?, time: MedicationDayTime) -> String {
        let key = doseKey(day: mode == .weekly ? day : nil, time: time)
        return clockTimes[key, default: time.defaultClockTime]
    }

    func clockTimeText(for day: MedicationWeekday?, time: MedicationDayTime) -> String {
        MedicationTimeFormatting.displayText(for: clockTime(for: day, time: time))
    }

    func clockTimeMinutes(for day: MedicationWeekday?, time: MedicationDayTime) -> Int {
        MedicationTimeFormatting.minutes(for: clockTime(for: day, time: time))
    }

    func doseKey(day: MedicationWeekday?, time: MedicationDayTime) -> String {
        if let day {
            return "\(day.rawValue).\(time.rawValue)"
        }

        return time.rawValue
    }
}

enum MedicationTimeFormatting {
    static func displayText(for storedTime: String) -> String {
        let minutes = minutes(for: storedTime)
        let hour = minutes / 60
        let minute = minutes % 60
        let languageCode = UserDefaults.standard.string(forKey: AppLanguage.storageKey) ?? AppLanguage.english.rawValue
        if AppLanguage(code: languageCode) == .chinese {
            return String(format: "%02d:%02d", hour, minute)
        }

        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour % 12 == 0 ? 12 : hour % 12
        return String(format: "%d:%02d %@", displayHour, minute, period)
    }

    static func minutes(for storedTime: String) -> Int {
        let pieces = storedTime.split(separator: ":").compactMap { Int($0) }
        guard pieces.count == 2 else { return 0 }
        return max(0, min(23, pieces[0])) * 60 + max(0, min(59, pieces[1]))
    }

    static func storedTime(from date: Date, calendar: Calendar = .current) -> String {
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        return String(format: "%02d:%02d", hour, minute)
    }

    static func date(from storedTime: String, calendar: Calendar = .current) -> Date {
        let minutes = minutes(for: storedTime)
        let hour = minutes / 60
        let minute = minutes % 60
        return calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: Date()
        ) ?? Date()
    }
}

enum MedicationChecklistIdentifier {
    static func id(for medication: MedicationSchedule, day: MedicationWeekday?, time: MedicationDayTime) -> String {
        switch medication.mode {
        case .daily:
            return "\(medication.id.uuidString).\(time.rawValue)"
        case .intervalDays:
            return "\(medication.id.uuidString).interval.\(time.rawValue)"
        case .weekly:
            let dayKey = day?.rawValue ?? MedicationWeekday.today().rawValue
            return "\(medication.id.uuidString).\(dayKey).\(time.rawValue)"
        }
    }
}

enum MedicationReminderScheduler {
    private static let identifierPrefix = "medicine-reminder."
    private static let maxPendingNotifications = 60
    private static let horizonDays = 60

    static func reschedule(medications: [MedicationSchedule], calendar: Calendar = .current) {
        let center = UNUserNotificationCenter.current()

        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }

            center.getPendingNotificationRequests { existingRequests in
                let oldIDs = existingRequests
                    .map(\.identifier)
                    .filter { $0.hasPrefix(identifierPrefix) }

                if !oldIDs.isEmpty {
                    center.removePendingNotificationRequests(withIdentifiers: oldIDs)
                }

                let requests = notificationRequests(for: medications, calendar: calendar)
                requests.prefix(maxPendingNotifications).forEach { request in
                    center.add(request)
                }
            }
        }
    }

    private static func notificationRequests(for medications: [MedicationSchedule], calendar: Calendar) -> [UNNotificationRequest] {
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let upcomingDoses = medications.flatMap { medication in
            scheduledDoses(for: medication, from: today, now: now, calendar: calendar)
        }

        return upcomingDoses
            .sorted { $0.fireDate < $1.fireDate }
            .map { dose in
                let content = UNMutableNotificationContent()
                content.title = localizedAppString("Medicine Reminder")
                content.body = dose.bodyText
                content.sound = .default
                content.userInfo = [
                    "kind": "medicineReminder",
                    "medicationChecklistID": dose.checklistID
                ]

                let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: dose.fireDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                return UNNotificationRequest(identifier: dose.identifier, content: content, trigger: trigger)
            }
    }

    private static func scheduledDoses(
        for medication: MedicationSchedule,
        from today: Date,
        now: Date,
        calendar: Calendar
    ) -> [ScheduledMedicationDose] {
        let startDay = calendar.startOfDay(for: medication.startDate)
        let endDay = medicationEndDay(for: medication, calendar: calendar)
        var doses: [ScheduledMedicationDose] = []

        for offset in 0..<horizonDays {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today),
                  day >= startDay else {
                continue
            }

            if let endDay, day > endDay {
                continue
            }

            let dayTimes = dueTimes(for: medication, on: day, startDay: startDay, calendar: calendar)

            for dayTime in dayTimes {
                let doseDay = medication.mode == .weekly ? MedicationWeekday.from(date: day, calendar: calendar) : nil
                let storedTime = medication.clockTime(for: doseDay, time: dayTime)
                let minutes = MedicationTimeFormatting.minutes(for: storedTime)
                guard let fireDate = calendar.date(
                    bySettingHour: minutes / 60,
                    minute: minutes % 60,
                    second: 0,
                    of: day
                ), fireDate > now else {
                    continue
                }

                doses.append(
                    ScheduledMedicationDose(
                        identifier: "\(identifierPrefix)\(medication.id.uuidString).\(dateKey(day, calendar: calendar)).\(medication.doseKey(day: doseDay, time: dayTime))",
                        fireDate: fireDate,
                        bodyText: reminderBody(for: medication, day: doseDay, time: dayTime),
                        checklistID: MedicationChecklistIdentifier.id(for: medication, day: doseDay, time: dayTime)
                    )
                )
            }
        }

        return doses
    }

    private static func dueTimes(
        for medication: MedicationSchedule,
        on day: Date,
        startDay: Date,
        calendar: Calendar
    ) -> [MedicationDayTime] {
        switch medication.mode {
        case .daily:
            return medication.dailyTimes
        case .intervalDays:
            let daysSinceStart = calendar.dateComponents([.day], from: startDay, to: day).day ?? 0
            return daysSinceStart >= 0 && daysSinceStart % max(1, medication.intervalDays) == 0
                ? medication.dailyTimes
                : []
        case .weekly:
            guard let weekday = MedicationWeekday.from(date: day, calendar: calendar),
                  medication.weeklyDays.contains(weekday) else {
                return []
            }

            return medication.weeklyTimes
        }
    }

    private static func reminderBody(for medication: MedicationSchedule, day: MedicationWeekday?, time: MedicationDayTime) -> String {
        let name = medication.displayName.isEmpty ? "medicine" : medication.displayName
        let dose = medication.dose(for: day, time: time)
        return dose.isEmpty ? "Time to take \(name)." : "Time to take \(name) \(dose)."
    }

    private static func medicationEndDay(for medication: MedicationSchedule, calendar: Calendar) -> Date? {
        let duration = medication.duration.lowercased()
        guard duration.contains("day"),
              let numberText = duration.split(separator: " ").first,
              let days = Int(numberText) else {
            return nil
        }

        return calendar.date(byAdding: .day, value: max(0, days - 1), to: calendar.startOfDay(for: medication.startDate))
    }

    private static func dateKey(_ date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d%02d%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }
}

struct ScheduledMedicationDose {
    let identifier: String
    let fireDate: Date
    let bodyText: String
    let checklistID: String
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

struct DailyNotificationDismissState: Codable, Equatable {
    var dateKey: String
    var clearedIDs: [String]
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

                Text(LocalizedStringKey(option.title))
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

struct QuickLogEmptySelectionCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: "slider.horizontal.3")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 42, height: 42)
                    .background(AppTheme.accent.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text(localizedAppString("No quick-log buttons selected"))
                        .font(.headline.weight(.black))
                        .foregroundStyle(AppTheme.text)

                    Text(localizedAppString("Tap the slider icon in the top right to choose quick-log buttons."))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.panel)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(localizedAppString("Choose quick-log buttons"))
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

                                Text(LocalizedStringKey(option.title))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.text)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(14)
                            .background(AppTheme.panel)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(18)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(localizedAppString("Quick Logs"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(localizedAppString("Done")) {
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
    var displayIcon: String?
    var sleepDurationText: String?
    var isLoggedToday = true
    let action: () -> Void

    private var valueText: String {
        isLoggedToday ? (displayValue ?? localizedAppString(option.value)) : "--"
    }

    private var detailText: String {
        isLoggedToday ? (displayDetail ?? localizedAppString(option.detail)) : localizedAppString(option.emptyCaption)
    }

    private var iconName: String {
        displayIcon ?? option.icon
    }

    var body: some View {
        Button {
            action()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Text(LocalizedStringKey(option.title))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.text)
                    .lineLimit(2)
                    .frame(height: 30, alignment: .topLeading)

                if option.id != "sleep" {
                    HStack {
                        Spacer()
                        Image(systemName: iconName)
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(option.tint)
                        Spacer()
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(valueText)
                        .font(option.id == "sleep" ? .title3.weight(.black) : .caption.weight(.bold))
                        .foregroundStyle(AppTheme.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text(detailText)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
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

struct ModalToolbarTitle: View {
    let icon: String?
    let title: String
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            if let icon, !icon.isEmpty {
                Image(systemName: icon)
                    .font(.caption.weight(.black))
                    .foregroundStyle(tint)
            }

            Text(localizedAppString(title))
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .accessibilityElement(children: .combine)
    }
}

struct StickyBottomSaveButton: View {
    let title: String
    let tint: Color
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(localizedAppString(title))
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(isDisabled ? Color.secondary.opacity(0.45) : tint)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(isDisabled)
        .buttonStyle(.plain)
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial)
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
            VStack(spacing: 0) {
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
                                Text(localizedAppString("Sleep & Rest"))
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(AppTheme.text)

                                Text(String(format: localizedAppString("%@ tracked"), durationText))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }

                        VStack(alignment: .leading, spacing: 16) {
                            Text(localizedAppString("Sleep Times"))
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.text)

                            TimeWheelPicker(title: localizedAppString("Fell asleep at"), selection: $fellAsleepAt)
                            TimeWheelPicker(title: localizedAppString("Woke up at"), selection: $wokeUpAt)
                        }
                        .authPanel()

                        VStack(alignment: .leading, spacing: 12) {
                            Text(localizedAppString("Rest Quality"))
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
                                            Text(LocalizedStringKey(quality.title))
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
                            Text(localizedAppString("Waking Counter"))
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

                                Text(localizedAppString(wakingCount == 1 ? "wake-up" : "wake-ups"))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)

                                Spacer()
                            }
                        }
                        .authPanel()

                        VStack(alignment: .leading, spacing: 8) {
                            Text(localizedAppString("Notes"))
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.text)

                            TextField(localizedAppString("Nap, bedtime routine, night waking, comfort item, etc."), text: $comments, axis: .vertical)
                                .textInputAutocapitalization(.never)
                                .lineLimit(3...6)
                                .padding(12)
                                .background(AppTheme.fieldBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .authPanel()
                    }
                    .padding(18)
                }
                StickyBottomSaveButton(title: "Save Log", tint: AppTheme.accent) {
                    save()
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(localizedAppString("Cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .principal) {
                    ModalToolbarTitle(icon: option.icon, title: option.title, tint: option.tint)
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
        localizedDateString(date, dateStyle: .none, timeStyle: .short)
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
            Text(localizedAppString(title))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.text)

            DatePicker(localizedAppString(title), selection: $selection, displayedComponents: [.hourAndMinute])
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

struct DigestionSnapshotSheet: View {
    @Environment(\.dismiss) private var dismiss

    let option: SnapshotOption
    let onSave: (HealthLogEntry) -> Void

    @State private var movementTime = Date()
    @State private var selectedStoolType = 4
    @State private var selectedVolume = "Medium"
    @State private var selectedColor = DigestionStoolColor.brown
    @State private var hasStraining: Bool?
    @State private var hasGas: Bool?
    @State private var hasUndigestedFood: Bool?
    @State private var isInfoPresented = false

    private let volumeOptions = ["Small", "Medium", "Large"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 12) {
                        Text(localizedAppString("Movement time"))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.text)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        Spacer(minLength: 8)

                        DatePicker(
                            "",
                            selection: $movementTime,
                            displayedComponents: [.hourAndMinute]
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                    }
                    .authPanel()

                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(localizedAppString("Consistency"))
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(AppTheme.text)

                                Text(localizedAppString("The Bristol Stool Chart"))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button {
                                isInfoPresented = true
                            } label: {
                                Image(systemName: "info.circle.fill")
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(option.tint)
                                    .frame(width: 34, height: 34)
                                    .background(option.tint.opacity(0.14))
                                    .clipShape(Circle())
                            }
                            .accessibilityLabel(localizedAppString("Show stool type descriptions"))
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(1...7, id: \.self) { type in
                                    StoolTypePickerCard(
                                        type: type,
                                        isSelected: selectedStoolType == type,
                                        tint: option.tint
                                    ) {
                                        selectedStoolType = type
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .authPanel()

                    VStack(alignment: .leading, spacing: 12) {
                        Text(localizedAppString("Volume"))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.text)

                        HStack(spacing: 10) {
                            ForEach(volumeOptions, id: \.self) { volume in
                                Button {
                                    selectedVolume = volume
                                } label: {
                                    Text(localizedAppString(volume))
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(selectedVolume == volume ? .white : AppTheme.text)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(selectedVolume == volume ? option.tint : AppTheme.fieldBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .authPanel()

                    VStack(alignment: .leading, spacing: 12) {
                        Text(localizedAppString("Color Check"))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.text)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                            ForEach(DigestionStoolColor.allCases) { stoolColor in
                                Button {
                                    selectedColor = stoolColor
                                } label: {
                                    VStack(spacing: 7) {
                                        Circle()
                                            .fill(stoolColor.swatch)
                                            .frame(width: 30, height: 30)
                                            .overlay {
                                                Circle()
                                                    .stroke(
                                                        selectedColor == stoolColor ? option.tint : Color.black.opacity(0.12),
                                                        lineWidth: selectedColor == stoolColor ? 3 : 1
                                                    )
                                            }

                                        Text(localizedAppString(stoolColor.title))
                                            .font(.caption2.weight(.bold))
                                            .foregroundStyle(AppTheme.text)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.75)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(selectedColor == stoolColor ? option.tint.opacity(0.14) : AppTheme.fieldBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .authPanel()

                    VStack(alignment: .leading, spacing: 12) {
                        Text(localizedAppString("Pain & Strain"))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.text)

                        DigestionYesNoRow(
                            title: "Straining/Discomfort during the movement?",
                            value: $hasStraining,
                            tint: option.tint
                        )

                        DigestionYesNoRow(
                            title: "Excessive gas or bloating noticed afterward?",
                            value: $hasGas,
                            tint: option.tint
                        )

                        DigestionYesNoRow(
                            title: "Visible undigested food in the stool?",
                            value: $hasUndigestedFood,
                            tint: option.tint
                        )
                    }
                    .authPanel()
                    }
                    .padding(18)
                }
                StickyBottomSaveButton(title: "Save Log", tint: AppTheme.accent) {
                    save()
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(localizedAppString("Cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .principal) {
                    ModalToolbarTitle(icon: option.icon, title: option.title, tint: option.tint)
                }

            }
        }
        .presentationDetents([.large])
        .sheet(isPresented: $isInfoPresented) {
            BristolStoolInfoSheet(tint: option.tint)
        }
    }

    private func save() {
        let group = BristolStoolGuide.group(for: selectedStoolType)
        let description = BristolStoolGuide.description(for: selectedStoolType)
        let value = "\(localizedAppString("Type")) \(selectedStoolType) · \(localizedAppString(group))"
        let detailLines = [
            "\(localizedAppString("Time")): \(localizedDateString(movementTime, dateStyle: .none, timeStyle: .short))",
            "\(localizedAppString("Consistency")): \(localizedAppString("Type")) \(selectedStoolType) - \(localizedAppString(description))",
            "\(localizedAppString("Volume")): \(localizedAppString(selectedVolume))",
            "\(localizedAppString("Color")): \(localizedAppString(selectedColor.title))",
            "\(localizedAppString("Straining/Discomfort")): \(answerText(hasStraining))",
            "\(localizedAppString("Gas/Bloating")): \(answerText(hasGas))",
            "\(localizedAppString("Undigested Food")): \(answerText(hasUndigestedFood))"
        ]

        let entry = HealthLogEntry(
            id: UUID(),
            type: .snapshot,
            categoryID: option.id,
            title: option.title,
            timestamp: movementTime,
            severity: BristolStoolGuide.severity(for: selectedStoolType),
            value: value,
            comments: detailLines.joined(separator: "\n")
        )
        onSave(entry)
        dismiss()
    }

    private func answerText(_ value: Bool?) -> String {
        guard let value else { return "--" }
        return localizedAppString(value ? "Yes" : "No")
    }
}

enum DigestionStoolColor: String, CaseIterable, Identifiable {
    case brown
    case green
    case clayWhite
    case black
    case red

    var id: String { rawValue }

    var title: String {
        switch self {
        case .brown:
            return "Brown"
        case .green:
            return "Green"
        case .clayWhite:
            return "Clay/White"
        case .black:
            return "Black"
        case .red:
            return "Red"
        }
    }

    var swatch: Color {
        switch self {
        case .brown:
            return Color(red: 0.48, green: 0.25, blue: 0.13)
        case .green:
            return Color(red: 0.28, green: 0.55, blue: 0.25)
        case .clayWhite:
            return Color(red: 0.90, green: 0.86, blue: 0.72)
        case .black:
            return Color(red: 0.08, green: 0.07, blue: 0.06)
        case .red:
            return Color(red: 0.73, green: 0.12, blue: 0.11)
        }
    }
}

enum BristolStoolGuide {
    static func group(for type: Int) -> String {
        switch type {
        case 1...2:
            return "Constipation"
        case 3...4:
            return "Optimal"
        default:
            return "Diarrhea/Intolerance"
        }
    }

    static func description(for type: Int) -> String {
        switch type {
        case 1:
            return "Separate hard lumps, like little pebbles."
        case 2:
            return "Hard and lumpy, starting to resemble a sausage."
        case 3:
            return "Sausage-shaped with cracks on the surface."
        case 4:
            return "Smooth and soft, snake-like."
        case 5:
            return "Soft blobs with clear-cut edges."
        case 6:
            return "Fluffy, mushy pieces with ragged edges."
        default:
            return "Watery with no solid pieces."
        }
    }

    static func severity(for type: Int) -> Int {
        switch type {
        case 3...4:
            return 1
        case 2, 5:
            return 2
        default:
            return 3
        }
    }
}

struct StoolTypePickerCard: View {
    let type: Int
    let isSelected: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                BristolStoolIcon(type: type)
                    .frame(width: 92, height: 58)

                Text("\(localizedAppString("Type")) \(type)")
                    .font(.caption.weight(.black))
                    .foregroundStyle(AppTheme.text)

                Text(localizedAppString(BristolStoolGuide.group(for: type)))
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(10)
            .frame(width: 120, height: 132)
            .background(isSelected ? tint.opacity(0.18) : AppTheme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? tint : Color.clear, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
    }
}

struct BristolStoolIcon: View {
    let type: Int

    var body: some View {
        BundledPNGImage(name: "BristolStoolType\(type)")
    }
}

struct BundledPNGImage: View {
    let name: String

    var body: some View {
        if let image = bundledImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(AppTheme.fieldBackground)
        }
    }

    private var bundledImage: UIImage? {
        if let url = Bundle.main.url(forResource: name, withExtension: "png"),
           let image = UIImage(contentsOfFile: url.path) {
            return image
        }

        return UIImage(named: name) ?? UIImage(named: "\(name).png")
    }
}

struct DigestionYesNoRow: View {
    let title: String
    @Binding var value: Bool?
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localizedAppString(title))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.text)

            HStack(spacing: 10) {
                yesNoButton(title: "Yes", option: true)
                yesNoButton(title: "No", option: false)
            }
        }
    }

    private func yesNoButton(title: String, option: Bool) -> some View {
        Button {
            value = value == option ? nil : option
        } label: {
            Text(localizedAppString(title))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(value == option ? .white : AppTheme.text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(value == option ? tint : AppTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct BristolStoolInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    let tint: Color

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(1...7, id: \.self) { type in
                        HStack(alignment: .top, spacing: 12) {
                            BristolStoolIcon(type: type)
                                .frame(width: 76, height: 48)
                                .padding(8)
                                .background(tint.opacity(0.10))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(localizedAppString("Type")) \(type)")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(AppTheme.text)

                                Text(localizedAppString(BristolStoolGuide.group(for: type)))
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(tint)

                                Text(localizedAppString(BristolStoolGuide.description(for: type)))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.panel)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .padding(18)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(localizedAppString("Bristol Stool Chart"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(localizedAppString("Done")) {
                        dismiss()
                    }
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                }
            }
        }
        .presentationDetents([.medium, .large])
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
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
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
                                Text(LocalizedStringKey(target.valuePrompt))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.text)

                                TextField(
                                    target.logType == .quickLog
                                        ? localizedAppString("Short note")
                                        : localizedAppString("Example: 7 hours, normal, 2/5"),
                                    text: $value
                                )
                                .textInputAutocapitalization(.never)
                                .padding(12)
                                .background(AppTheme.fieldBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("\(localizedAppString("Severity")): \(Int(severity))/5")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.text)

                                Slider(value: $severity, in: 1...5, step: 1)
                                    .tint(target.tint)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text(localizedAppString("Comments"))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.text)

                                TextField(localizedAppString("Add details, context, triggers, or what helped"), text: $comments, axis: .vertical)
                                    .textInputAutocapitalization(.never)
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
                StickyBottomSaveButton(title: "Save Log", tint: AppTheme.accent) {
                    save()
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(localizedAppString("Cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .principal) {
                    ModalToolbarTitle(icon: target.icon, title: target.title, tint: target.tint)
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

struct MeltdownLogEntrySheet: View {
    @Environment(\.dismiss) private var dismiss

    let option: QuickLogOption
    let onSave: (HealthLogEntry) -> Void

    @State private var timestamp = Date()
    @State private var intensity = 3.0
    @State private var selectedTriggers: Set<String> = []
    @State private var selectedDuration = ""
    @State private var selectedCalmingTools: Set<String> = []
    @State private var notes = ""

    private let triggerOptions = [
        "Loud Noise",
        "Crowds",
        "Transitioning",
        "Hunger",
        "Fatigue",
        "Unknown"
    ]

    private let durationOptions = [
        "<5 mins",
        "5-15 mins",
        "15-30 mins",
        "30+ mins"
    ]

    private let calmingToolOptions = [
        "Deep Pressure",
        "Headphones",
        "Dim Lights",
        "Weighted Blanket",
        "Redirection"
    ]

    private var intensityDescription: String {
        switch Int(intensity) {
        case 1:
            return "Mild Agitation/Crying"
        case 2:
            return "Low Distress"
        case 3:
            return "Moderate Meltdown"
        case 4:
            return "High Distress"
        default:
            return "Severe Meltdown/Safety Risk"
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        meltdownHeader

                        timestampCard

                        intensityCard

                        meltdownMultiSelectSection(
                            icon: "exclamationmark.triangle",
                            title: "Triggers",
                            options: triggerOptions,
                            selection: $selectedTriggers
                        )

                        meltdownSingleSelectSection(
                            icon: "clock",
                            title: "Duration",
                            options: durationOptions,
                            selection: $selectedDuration
                        )

                        meltdownMultiSelectSection(
                            icon: "heart.circle",
                            title: "Calming Tools Tried",
                            options: calmingToolOptions,
                            selection: $selectedCalmingTools
                        )

                        notesCard
                    }
                    .padding(18)
                }
                StickyBottomSaveButton(title: "Save Log", tint: AppTheme.accent) {
                    save()
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationDetents([.large])
    }

    private var meltdownHeader: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(option.tint.opacity(0.18))
                    .frame(width: 52, height: 52)

                Image(systemName: option.icon)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(option.tint)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(localizedAppString("Log Meltdown"))
                    .font(.title.weight(.black))
                    .foregroundStyle(AppTheme.text)

                Text(localizedAppString("Track and understand what happened."))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.fieldBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(localizedAppString("Close"))
        }
        .padding(.top, 2)
    }

    private var timestampCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "calendar.badge.clock")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 30, height: 30)
                .background(AppTheme.accent.opacity(0.1))
                .clipShape(Circle())

            Text(localizedAppString("Timestamp"))
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 4)

            DatePicker("", selection: $timestamp, displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(.compact)
                .fixedSize()

            DatePicker("", selection: $timestamp, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .datePickerStyle(.compact)
                .fixedSize()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.035), radius: 10, x: 0, y: 5)
    }

    private var intensityCard: some View {
        meltdownSectionCard(icon: "waveform.path.ecg", title: "Intensity") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(localizedAppString("How intense was it?"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(Int(intensity))/5")
                        .font(.headline.weight(.black))
                        .foregroundStyle(option.tint)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(option.tint.opacity(0.12))
                        .overlay {
                            Capsule()
                                .stroke(option.tint.opacity(0.45), lineWidth: 1)
                        }
                        .clipShape(Capsule())
                }

                Slider(value: $intensity, in: 1...5, step: 1)
                    .tint(option.tint)
                    .padding(.vertical, 2)

                Text(localizedAppString(intensityDescription))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(option.tint)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 7)
                    .background(option.tint.opacity(0.12))
                    .clipShape(Capsule())
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private var notesCard: some View {
        meltdownSectionCard(icon: "note.text", title: "Notes") {
            TextField(localizedAppString("Add any additional details about what happened..."), text: $notes, axis: .vertical)
                .textInputAutocapitalization(.sentences)
                .lineLimit(3...6)
                .padding(12)
                .background(AppTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func meltdownSectionCard<Content: View>(
        icon: String,
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 30, height: 30)
                    .background(AppTheme.accent.opacity(0.1))
                    .clipShape(Circle())

                Text(localizedAppString(title))
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.text)
            }

            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.035), radius: 10, x: 0, y: 5)
    }

    private func meltdownMultiSelectSection(
        icon: String,
        title: String,
        options: [String],
        selection: Binding<Set<String>>
    ) -> some View {
        meltdownSectionCard(icon: icon, title: title) {
            FlowLayout(spacing: 8, rowSpacing: 8) {
                ForEach(options, id: \.self) { chip in
                    meltdownOptionChip(
                        title: chip,
                        icon: meltdownOptionIcon(for: chip),
                        isSelected: selection.wrappedValue.contains(chip),
                        allowsCheckmark: true
                    ) {
                        if selection.wrappedValue.contains(chip) {
                            selection.wrappedValue.remove(chip)
                        } else {
                            selection.wrappedValue.insert(chip)
                        }
                    }
                }
            }
        }
    }

    private func meltdownSingleSelectSection(
        icon: String,
        title: String,
        options: [String],
        selection: Binding<String>
    ) -> some View {
        meltdownSectionCard(icon: icon, title: title) {
            FlowLayout(spacing: 8, rowSpacing: 8) {
                ForEach(options, id: \.self) { chip in
                    meltdownOptionChip(
                        title: chip,
                        icon: "clock",
                        isSelected: selection.wrappedValue == chip,
                        allowsCheckmark: false
                    ) {
                        selection.wrappedValue = selection.wrappedValue == chip ? "" : chip
                    }
                }
            }
        }
    }

    private func meltdownOptionChip(
        title: String,
        icon: String,
        isSelected: Bool,
        allowsCheckmark: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(isSelected ? AppTheme.accent : AppTheme.accent.opacity(0.9))

                Text(localizedAppString(title))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? AppTheme.accent : AppTheme.text)

                if allowsCheckmark {
                    Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(isSelected ? AppTheme.accent : .secondary.opacity(0.55))
                }
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 11)
            .background(isSelected ? AppTheme.accent.opacity(0.12) : Color.white)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(isSelected ? AppTheme.accent.opacity(0.55) : Color.black.opacity(0.08), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private func meltdownOptionIcon(for option: String) -> String {
        switch option {
        case "Loud Noise":
            return "speaker.wave.2"
        case "Crowds":
            return "person.2"
        case "Transitioning":
            return "arrow.triangle.2.circlepath"
        case "Hunger":
            return "fork.knife"
        case "Fatigue":
            return "moon.zzz"
        case "Unknown":
            return "questionmark.circle"
        case "Deep Pressure":
            return "hands.sparkles"
        case "Headphones":
            return "headphones"
        case "Dim Lights":
            return "lightbulb"
        case "Weighted Blanket":
            return "rectangle.fill.on.rectangle.fill"
        case "Redirection":
            return "arrow.uturn.left"
        default:
            return "circle"
        }
    }

    private func save() {
        let durationText = selectedDuration.isEmpty ? localizedAppString("Not selected") : localizedAppString(selectedDuration)
        let triggersText = selectedTriggers.isEmpty
            ? localizedAppString("Not selected")
            : selectedTriggers.sorted().map { localizedAppString($0) }.joined(separator: ", ")
        let toolsText = selectedCalmingTools.isEmpty
            ? localizedAppString("Not selected")
            : selectedCalmingTools.sorted().map { localizedAppString($0) }.joined(separator: ", ")
        let intensityText = "\(Int(intensity))/5 - \(localizedAppString(intensityDescription))"
        let comments = [
            "Timestamp: \(localizedDateString(timestamp, dateStyle: .medium, timeStyle: .short))",
            "Intensity: \(intensityText)",
            "Triggers: \(triggersText)",
            "Duration: \(durationText)",
            "Calming Tools Tried: \(toolsText)",
            notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? nil
                : "Notes: \(notes.trimmingCharacters(in: .whitespacesAndNewlines))"
        ].compactMap { $0 }.joined(separator: "\n")

        let entry = HealthLogEntry(
            id: UUID(),
            type: .quickLog,
            categoryID: option.id,
            title: option.title,
            timestamp: timestamp,
            severity: Int(intensity),
            value: "\(localizedAppString("Meltdown")) · \(durationText)",
            comments: comments
        )

        onSave(entry)
        dismiss()
    }
}

struct StimmingTicsLogEntrySheet: View {
    @Environment(\.dismiss) private var dismiss

    let option: QuickLogOption
    let onSave: (HealthLogEntry) -> Void

    @State private var timestamp = Date()
    @State private var selectedBehaviorTypes: Set<String> = []
    @State private var selectedFrequency = ""
    @State private var stateValue = 0.0
    @State private var selectedContexts: Set<String> = []

    private let behaviorOptions = [
        "Hand Flapping",
        "Vocal Tics/Sounds",
        "Rocking",
        "Pacing",
        "Eye Blinking",
        "Head Shaking",
        "Repetitive Phrases"
    ]

    private let frequencyOptions = [
        "Low (Occasional)",
        "Medium (Frequent)",
        "High (Constant)"
    ]

    private let contextOptions = [
        "School/Therapy",
        "Screen Time",
        "Transitioning",
        "Public Place",
        "Relaxing at Home"
    ]

    private var apparentStateText: String {
        stateValue < 0.5 ? "Joyful/Regulating (Happy)" : "Anxious/Stressed"
    }

    private var severityFromFrequency: Int {
        switch selectedFrequency {
        case "High (Constant)":
            return 5
        case "Medium (Frequent)":
            return 3
        case "Low (Occasional)":
            return 1
        default:
            return stateValue < 0.5 ? 2 : 4
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 14) {
                        DatePicker(
                            localizedAppString("Timestamp"),
                            selection: $timestamp,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .font(.subheadline.weight(.semibold))

                        stimmingMultiSelectSection(
                            title: "Behavior Type",
                            options: behaviorOptions,
                            selection: $selectedBehaviorTypes
                        )

                        stimmingFrequencySection

                        apparentStateSection

                        stimmingMultiSelectSection(
                            title: "Context/Setting",
                            options: contextOptions,
                            selection: $selectedContexts
                        )
                    }
                    .authPanel()
                    }
                    .padding(18)
                }
                StickyBottomSaveButton(title: "Save Log", tint: AppTheme.accent) {
                    save()
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(localizedAppString("Cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .principal) {
                    ModalToolbarTitle(icon: option.icon, title: option.title, tint: option.tint)
                }

            }
        }
        .presentationDetents([.large])
    }

    private var stimmingFrequencySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(localizedAppString("Frequency"))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.text)

            VStack(spacing: 8) {
                ForEach(frequencyOptions, id: \.self) { frequency in
                    Button {
                        selectedFrequency = selectedFrequency == frequency ? "" : frequency
                    } label: {
                        HStack {
                            Text(localizedAppString(frequency))
                                .font(.headline.weight(.bold))
                                .foregroundStyle(selectedFrequency == frequency ? .white : AppTheme.text)

                            Spacer()

                            Image(systemName: selectedFrequency == frequency ? "checkmark.circle.fill" : "circle")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(selectedFrequency == frequency ? .white : .secondary.opacity(0.65))
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity)
                        .background(selectedFrequency == frequency ? option.tint : AppTheme.fieldBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var apparentStateSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(localizedAppString("Apparent State"))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.text)

                Spacer()

                Text(localizedAppString(apparentStateText))
                    .font(.caption.weight(.black))
                    .foregroundStyle(option.tint)
            }

            Picker(localizedAppString("Apparent State"), selection: $stateValue) {
                Text(localizedAppString("Joyful/Regulating (Happy)")).tag(0.0)
                Text(localizedAppString("Anxious/Stressed")).tag(1.0)
            }
            .pickerStyle(.segmented)
        }
    }

    private func stimmingMultiSelectSection(
        title: String,
        options: [String],
        selection: Binding<Set<String>>
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(localizedAppString(title))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.text)

            FlowLayout(spacing: 8, rowSpacing: 8) {
                ForEach(options, id: \.self) { chip in
                    CyclicVomitingOptionChip(
                        title: chip,
                        isSelected: selection.wrappedValue.contains(chip),
                        tint: option.tint
                    ) {
                        if selection.wrappedValue.contains(chip) {
                            selection.wrappedValue.remove(chip)
                        } else {
                            selection.wrappedValue.insert(chip)
                        }
                    }
                }
            }
        }
    }

    private func save() {
        let behaviorText = selectedBehaviorTypes.isEmpty
            ? localizedAppString("Not selected")
            : selectedBehaviorTypes.sorted().map { localizedAppString($0) }.joined(separator: ", ")
        let frequencyText = selectedFrequency.isEmpty ? localizedAppString("Not selected") : localizedAppString(selectedFrequency)
        let contextText = selectedContexts.isEmpty
            ? localizedAppString("Not selected")
            : selectedContexts.sorted().map { localizedAppString($0) }.joined(separator: ", ")
        let apparentState = localizedAppString(apparentStateText)

        let comments = [
            "Timestamp: \(localizedDateString(timestamp, dateStyle: .medium, timeStyle: .short))",
            "Behavior Type: \(behaviorText)",
            "Frequency: \(frequencyText)",
            "Apparent State: \(apparentState)",
            "Context/Setting: \(contextText)"
        ].joined(separator: "\n")

        let entry = HealthLogEntry(
            id: UUID(),
            type: .quickLog,
            categoryID: option.id,
            title: option.title,
            timestamp: timestamp,
            severity: severityFromFrequency,
            value: "\(localizedAppString("Stimming/Tics")) · \(frequencyText)",
            comments: comments
        )

        onSave(entry)
        dismiss()
    }
}

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
                ToolbarItem(placement: .topBarLeading) {
                    Button(localizedAppString("Cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .principal) {
                    ModalToolbarTitle(icon: option.icon, title: option.title, tint: option.tint)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(localizedAppString("Save Progress")) {
                        saveProgress()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
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

struct CyclicVomitingNavigationCard: View {
    let title: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.black))
                .foregroundStyle(tint)
                .frame(width: 18)

            Text(localizedAppString(title))
                .font(.subheadline.weight(.black))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.76)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 46)
        .background(tint.opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct QualityOfLifeScoreSummary {
    let total: String
    let physical: String
    let psychosocial: String
}

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

struct CyclicVomitingTimeField: View {
    let title: String
    @Binding var selection: Date
    let tint: Color
    @State private var isDatePickerPresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localizedAppString(title))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.text)

            HStack(spacing: 10) {
                Button {
                    isDatePickerPresented = true
                } label: {
                    Image(systemName: "calendar")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(tint)
                        .frame(width: 28, height: 28)
                        .background(tint.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                }
                .buttonStyle(.plain)
                .popover(isPresented: $isDatePickerPresented) {
                    VStack(spacing: 12) {
                        DatePicker(
                            "",
                            selection: $selection,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.graphical)
                        .labelsHidden()

                        Button(localizedAppString("Done")) {
                            isDatePickerPresented = false
                        }
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(tint)
                    }
                    .padding()
                    .frame(minWidth: 320)
                    .presentationCompactAdaptation(.popover)
                }

                DatePicker(
                    "",
                    selection: $selection,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .labelsHidden()
                .datePickerStyle(.compact)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(AppTheme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(tint.opacity(0.18), lineWidth: 1)
            )
        }
    }
}

struct CyclicVomitingYearMonthField: View {
    @Binding var year: String
    @Binding var month: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(localizedAppString("Onset Time of Recurrent Vomiting"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.text)

            HStack(spacing: 10) {
                CyclicVomitingCompactTextField(
                    placeholder: "Year",
                    text: $year
                )

                CyclicVomitingCompactTextField(
                    placeholder: "Month",
                    text: $month
                )
            }
        }
    }
}

struct CyclicVomitingCompactTextField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(localizedAppString(placeholder), text: digitsOnlyText)
            .keyboardType(.numberPad)
            .padding(12)
            .background(AppTheme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var digitsOnlyText: Binding<String> {
        Binding(
            get: { text },
            set: { newValue in
                text = newValue.filter(\.isNumber)
            }
        )
    }
}

struct CyclicVomitingTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var lineLimit: ClosedRange<Int> = 1...3

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localizedAppString(title))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.text)

            TextField(localizedAppString(placeholder), text: $text, axis: .vertical)
                .textInputAutocapitalization(.never)
                .lineLimit(lineLimit)
                .padding(12)
                .background(AppTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

struct CyclicVomitingFormSection<Content: View>: View {
    let id: String
    let title: String
    let icon: String
    let tint: Color
    let isCollapsed: Bool
    let onToggle: () -> Void
    let content: Content

    init(
        id: String,
        title: String,
        icon: String,
        tint: Color,
        isCollapsed: Bool,
        onToggle: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.tint = tint
        self.isCollapsed = isCollapsed
        self.onToggle = onToggle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(action: onToggle) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(tint)
                        .frame(width: 30, height: 30)
                        .background(tint.opacity(0.14))
                        .clipShape(Circle())

                    Text(localizedAppString(title))
                        .font(.headline.weight(.black))
                        .foregroundStyle(AppTheme.text)

                    Spacer()

                    Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                }
            }
            .buttonStyle(.plain)

            if !isCollapsed {
                content
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(.white.opacity(0.86))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.accent.opacity(0.10), lineWidth: 1)
        )
    }
}

struct CyclicVomitingYesNoPicker: View {
    let title: String
    @Binding var isYes: Bool?
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(localizedAppString(title))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.text)

            HStack(spacing: 10) {
                yesNoButton(title: "Yes", selected: isYes == true) {
                    isYes = isYes == true ? nil : true
                }
                yesNoButton(title: "No", selected: isYes == false) {
                    isYes = isYes == false ? nil : false
                }
            }
        }
    }

    private func yesNoButton(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(selected ? tint : .secondary.opacity(0.6))

                Text(localizedAppString(title))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.text)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

struct CyclicVomitingOptionSection: View {
    let title: String
    var titleNote = ""
    let options: [String]
    @Binding var selection: Set<String>
    let tint: Color
    let otherPlaceholder: String
    @Binding var otherText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !title.isEmpty {
                HStack(spacing: 6) {
                    Text(localizedAppString(title))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.text)

                    if !titleNote.isEmpty {
                        Text(localizedAppString(titleNote))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(tint)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(tint.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }

            FlowLayout(spacing: 8, rowSpacing: 8) {
                ForEach(options, id: \.self) { option in
                    CyclicVomitingOptionChip(
                        title: option,
                        isSelected: selection.contains(option),
                        tint: tint
                    ) {
                        toggle(option)
                    }
                }
            }

            if !otherPlaceholder.isEmpty {
                TextField(localizedAppString(otherPlaceholder), text: $otherText, axis: .vertical)
                    .textInputAutocapitalization(.never)
                    .lineLimit(1...3)
                    .padding(12)
                    .background(AppTheme.fieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private func toggle(_ option: String) {
        if selection.contains(option) {
            selection.remove(option)
            return
        }

        if option.hasPrefix("None") {
            selection = [option]
        } else {
            selection = selection.filter { !$0.hasPrefix("None") }
            selection.insert(option)
        }
    }
}

struct CyclicVomitingSingleChoiceSection: View {
    let title: String
    let options: [String]
    @Binding var selection: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(localizedAppString(title))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.text)

            FlowLayout(spacing: 8, rowSpacing: 8) {
                ForEach(options, id: \.self) { option in
                    CyclicVomitingOptionChip(
                        title: option,
                        isSelected: selection == option,
                        tint: tint
                    ) {
                        selection = selection == option ? "" : option
                    }
                }
            }
        }
    }
}

struct CyclicVomitingMeasurementField: View {
    let title: String
    let units: [String]
    @Binding var text: String
    @Binding var selectedUnit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localizedAppString(title))
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                TextField("", text: decimalText)
                    .keyboardType(.decimalPad)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.text)

                Menu {
                    ForEach(units, id: \.self) { unit in
                        Button(unit) {
                            selectedUnit = unit
                        }
                    }
                } label: {
                    HStack(spacing: 3) {
                        Text(selectedUnit)
                            .font(.caption.weight(.bold))

                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.black))
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(AppTheme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .onAppear {
            text = Self.sanitizedDecimal(text, fractionalDigits: 1)
            if !units.contains(selectedUnit), let firstUnit = units.first {
                selectedUnit = firstUnit
            }
        }
        .onChange(of: text) { _, newValue in
            let cleaned = Self.sanitizedDecimal(newValue, fractionalDigits: 1)
            if cleaned != newValue {
                text = cleaned
            }
        }
        .onChange(of: selectedUnit) { _, newValue in
            if !units.contains(newValue), let firstUnit = units.first {
                selectedUnit = firstUnit
            }
        }
    }

    private var decimalText: Binding<String> {
        Binding(
            get: { text },
            set: { newValue in
                text = Self.sanitizedDecimal(newValue, fractionalDigits: 1)
            }
        )
    }

    private static func sanitizedDecimal(_ value: String, fractionalDigits: Int) -> String {
        var result = ""
        var hasDecimal = false
        var digitsAfterDecimal = 0

        for character in value.replacingOccurrences(of: ",", with: ".") {
            if character.isNumber {
                if hasDecimal {
                    guard digitsAfterDecimal < fractionalDigits else { continue }
                    digitsAfterDecimal += 1
                }

                result.append(character)
            } else if character == ".", !hasDecimal {
                hasDecimal = true
                result.append(result.isEmpty ? "0." : ".")
            }
        }

        return result
    }
}

struct CyclicVomitingOptionChip: View {
    let title: String
    let isSelected: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(isSelected ? .white : .secondary.opacity(0.7))
                Text(localizedAppString(title))
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(isSelected ? .white : AppTheme.text)
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(isSelected ? tint : AppTheme.fieldBackground)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct CyclicVomitingNumberPicker: View {
    let title: String
    @Binding var value: Int
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(localizedAppString(title))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.text)
                Spacer()
                Text(localizedAppString("Times per Day"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 14) {
                Button {
                    value = max(0, value - 1)
                } label: {
                    Image(systemName: "minus")
                        .font(.headline.weight(.bold))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.bordered)
                .tint(tint)

                Text("\(value)")
                    .font(.title.weight(.black))
                    .foregroundStyle(AppTheme.text)
                    .frame(minWidth: 62)

                Button {
                    value = min(50, value + 1)
                } label: {
                    Image(systemName: "plus")
                        .font(.headline.weight(.bold))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(tint)

                Spacer()
            }
        }
    }
}

struct NutritionGoals: Codable, Equatable {
    var calorieGoal = ""
    var proteinGoal = ""
    var carbsGoal = ""
    var fatGoal = ""
    var calciumGoal = ""
    var vitaminDGoal = ""
    var ironGoal = ""
    var otherSupplements = ""
    var waterGoal = ""
    var notes = ""
    var lastUpdated = Date()
    var consumedDateKey = MedicationCheckState.todayKey
    var consumedCalories = 0
    var consumedProtein = 0
    var consumedCarbs = 0
    var consumedFat = 0

    enum CodingKeys: String, CodingKey {
        case calorieGoal
        case proteinGoal
        case carbsGoal
        case fatGoal
        case calciumGoal
        case vitaminDGoal
        case ironGoal
        case otherSupplements
        case waterGoal
        case notes
        case lastUpdated
        case consumedDateKey
        case consumedCalories
        case consumedProtein
        case consumedCarbs
        case consumedFat
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        calorieGoal = try container.decodeIfPresent(String.self, forKey: .calorieGoal) ?? ""
        proteinGoal = try container.decodeIfPresent(String.self, forKey: .proteinGoal) ?? ""
        carbsGoal = try container.decodeIfPresent(String.self, forKey: .carbsGoal) ?? ""
        fatGoal = try container.decodeIfPresent(String.self, forKey: .fatGoal) ?? ""
        calciumGoal = try container.decodeIfPresent(String.self, forKey: .calciumGoal) ?? ""
        vitaminDGoal = try container.decodeIfPresent(String.self, forKey: .vitaminDGoal) ?? ""
        ironGoal = try container.decodeIfPresent(String.self, forKey: .ironGoal) ?? ""
        otherSupplements = try container.decodeIfPresent(String.self, forKey: .otherSupplements) ?? ""
        waterGoal = try container.decodeIfPresent(String.self, forKey: .waterGoal) ?? ""
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        lastUpdated = try container.decodeIfPresent(Date.self, forKey: .lastUpdated) ?? Date()
        consumedDateKey = try container.decodeIfPresent(String.self, forKey: .consumedDateKey) ?? MedicationCheckState.todayKey
        consumedCalories = try container.decodeIfPresent(Int.self, forKey: .consumedCalories) ?? 0
        consumedProtein = try container.decodeIfPresent(Int.self, forKey: .consumedProtein) ?? 0
        consumedCarbs = try container.decodeIfPresent(Int.self, forKey: .consumedCarbs) ?? 0
        consumedFat = try container.decodeIfPresent(Int.self, forKey: .consumedFat) ?? 0
    }

    var isEmpty: Bool {
        [
            calorieGoal,
            proteinGoal,
            carbsGoal,
            fatGoal,
            calciumGoal,
            vitaminDGoal,
            ironGoal,
            otherSupplements,
            waterGoal,
            notes
        ]
        .allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    var summaryLines: [String] {
        var lines: [String] = []
        appendProgressLine("Calories", current: consumedCalories, goal: calorieGoal, unit: "kcal", to: &lines)
        appendProgressLine("Protein", current: consumedProtein, goal: proteinGoal, unit: "g", to: &lines)
        appendProgressLine("Carbs", current: consumedCarbs, goal: carbsGoal, unit: "g", to: &lines)
        appendProgressLine("Fats", current: consumedFat, goal: fatGoal, unit: "g", to: &lines)
        appendLine("Calcium", calciumGoal, "mg", to: &lines)
        appendLine("Vitamin D", vitaminDGoal, "IU", to: &lines)
        appendLine("Iron", ironGoal, "mg", to: &lines)
        appendLine("Water", waterGoal, "", to: &lines)

        let trimmedSupplements = otherSupplements.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSupplements.isEmpty {
            lines.append("Other supplements: \(trimmedSupplements)")
        }

        return lines
    }

    mutating func applyMealEstimate(_ estimate: MealNutritionEstimate) {
        resetDailyProgressIfNeeded()
        consumedCalories += estimate.calories
        consumedProtein += estimate.protein
        consumedCarbs += estimate.carbs
        consumedFat += estimate.fat
        lastUpdated = Date()
    }

    mutating func resetDailyProgressIfNeeded() {
        guard consumedDateKey != MedicationCheckState.todayKey else { return }
        consumedDateKey = MedicationCheckState.todayKey
        consumedCalories = 0
        consumedProtein = 0
        consumedCarbs = 0
        consumedFat = 0
    }

    var hasConsumedNutritionToday: Bool {
        consumedDateKey == MedicationCheckState.todayKey
            && [consumedCalories, consumedProtein, consumedCarbs, consumedFat].contains { $0 > 0 }
    }

    private func appendLine(_ label: String, _ value: String, _ unit: String, to lines: inout [String]) {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else { return }
        lines.append(unit.isEmpty ? "\(label): \(trimmedValue)" : "\(label): \(trimmedValue) \(unit)")
    }

    private func appendProgressLine(_ label: String, current: Int, goal: String, unit: String, to lines: inout [String]) {
        let trimmedGoal = goal.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedGoal.isEmpty {
            lines.append("\(label): \(current)/\(trimmedGoal) \(unit)")
        } else if current > 0 {
            lines.append("\(label): \(current) \(unit)")
        }
    }
}

struct NutritionSnapshotSheet: View {
    @Environment(\.dismiss) private var dismiss

    let userID: Int
    let option: SnapshotOption
    let onSave: (HealthLogEntry) -> Void

    @AppStorage private var goalsData: Data
    @State private var goals = NutritionGoals()
    @State private var isGoalsExpanded = false

    init(userID: Int, option: SnapshotOption, onSave: @escaping (HealthLogEntry) -> Void) {
        self.userID = userID
        self.option = option
        self.onSave = onSave
        self._goalsData = AppStorage(wrappedValue: Data(), "nutrient.\(userID).nutritionGoalsData")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 16) {
                            if goals.isEmpty {
                                NutritionGoalsEditor(goals: $goals)
                            } else {
                                NutritionGoalsSummary(goals: goals)

                                DisclosureGroup(isExpanded: $isGoalsExpanded) {
                                    NutritionGoalsEditor(goals: $goals)
                                        .padding(.top, 12)
                                } label: {
                                    Text(localizedAppString("View Nutrition Goals"))
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(AppTheme.accent)
                                }
                                .tint(AppTheme.accent)
                            }
                        }
                        .authPanel()
                    }
                    .padding(18)
                }
                StickyBottomSaveButton(title: "Save", tint: AppTheme.accent) {
                    save()
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(localizedAppString("Cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .principal) {
                    ModalToolbarTitle(icon: option.icon, title: option.title, tint: option.tint)
                }

            }
        }
        .presentationDetents([.large])
        .onAppear {
            goals = storedGoals
            let previousDateKey = goals.consumedDateKey
            goals.resetDailyProgressIfNeeded()
            if previousDateKey != goals.consumedDateKey {
                saveGoals(goals)
            }
            isGoalsExpanded = goals.isEmpty
        }
    }

    private func save() {
        goals.lastUpdated = Date()
        saveGoals(goals)

        let summaryLines = goals.summaryLines
        let entry = HealthLogEntry(
            id: UUID(),
            type: .snapshot,
            categoryID: option.id,
            title: option.title,
            timestamp: Date(),
            severity: 1,
            value: summaryLines.isEmpty ? "Nutrition goals saved" : summaryLines.joined(separator: "\n"),
            comments: goals.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        onSave(entry)
        dismiss()
    }

    private var storedGoals: NutritionGoals {
        guard !goalsData.isEmpty,
              let savedGoals = try? JSONDecoder().decode(NutritionGoals.self, from: goalsData) else {
            return NutritionGoals()
        }

        return savedGoals
    }

    private func saveGoals(_ goals: NutritionGoals) {
        if let data = try? JSONEncoder().encode(goals) {
            goalsData = data
        }
    }
}

struct NutritionGoalsSummary: View {
    let goals: NutritionGoals

    private var rows: [String] {
        goals.summaryLines.isEmpty ? [localizedAppString("Nutrition goals saved")] : Array(goals.summaryLines.prefix(4))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(localizedAppString("Nutrition Goals"))
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.text)

            ForEach(rows, id: \.self) { row in
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.accent)

                    Text(localizedSavedAIText(row))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(AppTheme.fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct NutritionGoalsEditor: View {
    @Binding var goals: NutritionGoals

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            NutritionGoalSection(title: "Calories") {
                NutritionGoalField(title: "Daily calorie goal", placeholder: "kcal", text: $goals.calorieGoal)
            }

            NutritionGoalSection(title: "Macronutrients") {
                NutritionGoalField(title: "Protein", placeholder: "grams", text: $goals.proteinGoal)
                NutritionGoalField(title: "Carbs", placeholder: "grams", text: $goals.carbsGoal)
                NutritionGoalField(title: "Fats", placeholder: "grams", text: $goals.fatGoal)
            }

            NutritionGoalSection(title: "Micronutrient Supplementation") {
                NutritionGoalField(title: "Calcium", placeholder: "mg", text: $goals.calciumGoal)
                NutritionGoalField(title: "Vitamin D", placeholder: "IU", text: $goals.vitaminDGoal)
                NutritionGoalField(title: "Iron", placeholder: "mg", text: $goals.ironGoal)

                TextField("Other supplements or vitamins", text: $goals.otherSupplements, axis: .vertical)
                    .textInputAutocapitalization(.never)
                    .lineLimit(2...4)
                    .padding(12)
                    .background(AppTheme.fieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            NutritionGoalSection(title: "Water Hydration") {
                NutritionGoalField(title: "Daily water goal", placeholder: "cups or oz", text: $goals.waterGoal)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(localizedAppString("Notes"))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.text)

                TextField(localizedAppString("Diet restrictions, feeding notes, texture needs, or parent reminders"), text: $goals.notes, axis: .vertical)
                    .textInputAutocapitalization(.never)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(AppTheme.fieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }
}

struct NutritionGoalsPage: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var goals: NutritionGoals
    let onSave: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    PageHeader(
                        icon: "leaf.fill",
                        title: "Nutrition Goals",
                        subtitle: "Calories, macros, supplements, and hydration"
                    )

                    NutritionGoalsSummary(goals: goals)

                    NutritionGoalsEditor(goals: $goals)
                        .padding(16)
                        .background(AppTheme.panel)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(20)
            }

            StickyBottomSaveButton(title: "Save", tint: AppTheme.accent) {
                onSave()
                dismiss()
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(localizedAppString("Nutrition Goals"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct NutritionGoalSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(localizedAppString(title))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.text)

            VStack(spacing: 10) {
                content
            }
        }
    }
}

struct NutritionGoalField: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Text(localizedAppString(title))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.text)
                .frame(maxWidth: .infinity, alignment: .leading)

            TextField(localizedAppString(placeholder), text: $text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(.subheadline.weight(.bold))
                .padding(10)
                .frame(width: 118)
                .background(AppTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}

enum MoodLogStep {
    case kind
    case valence
    case words
    case cause
}

enum MoodLogKind: String, CaseIterable, Identifiable {
    case currentEmotion = "Current Emotion"
    case todaysMood = "Today's Mood"

    var id: String { rawValue }
}

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

struct MoodLogSheet: View {
    @Environment(\.dismiss) private var dismiss

    let option: QuickLogOption
    let onSave: (HealthLogEntry) -> Void

    @State private var step: MoodLogStep = .kind
    @State private var selectedKind: MoodLogKind?
    @State private var valence = 4
    @State private var selectedWords: Set<String> = []
    @State private var cause = ""

    private var wordGroup: MoodWordGroup {
        MoodWordGroup.group(for: valence)
    }

    private var nextTitle: String {
        step == .cause ? "Done" : "Next"
    }

    private var canContinue: Bool {
        switch step {
        case .kind:
            return selectedKind != nil
        case .valence:
            return true
        case .words:
            return !selectedWords.isEmpty
        case .cause:
            return true
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        switch step {
                        case .kind:
                            kindStep
                        case .valence:
                            valenceStep
                        case .words:
                            wordsStep
                        case .cause:
                            causeStep
                        }
                    }
                    .padding(18)
                }

                Button {
                    advance()
                } label: {
                    Text(nextTitle)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(canContinue ? option.tint : Color.secondary.opacity(0.45))
                        .clipShape(Capsule())
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                }
                .disabled(!canContinue)
                .buttonStyle(.plain)
                .background(AppTheme.background)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(step == .kind ? "Cancel" : "Back") {
                        goBack()
                    }
                    .foregroundStyle(AppTheme.accent)
                }

                ToolbarItem(placement: .principal) {
                    ModalToolbarTitle(icon: option.icon, title: option.title, tint: option.tint)
                }
            }
        }
        .presentationDetents([.large])
    }

    private var kindStep: some View {
        VStack(spacing: 12) {
            ForEach(MoodLogKind.allCases) { kind in
                Button {
                    selectedKind = kind
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(LocalizedStringKey(kind.rawValue))
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.text)

                            Text(kind == .currentEmotion ? currentTimeText : localizedAppString("For the whole day"))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: selectedKind == kind ? "checkmark.circle.fill" : "circle")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(selectedKind == kind ? option.tint : .secondary)
                    }
                    .padding(16)
                    .background(selectedKind == kind ? option.tint.opacity(0.18) : AppTheme.panel)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(selectedKind == kind ? option.tint.opacity(0.5) : Color.clear, lineWidth: 2)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var valenceStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizedStringKey(MoodValence.title(for: valence)))
                .font(.title2.weight(.black))
                .foregroundStyle(AppTheme.text)

            MoodValenceSlider(value: $valence, tint: option.tint)
        }
        .authPanel()
    }

    private var wordsStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(LocalizedStringKey(wordGroup.title))
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.text)

            FlowLayout(spacing: 9, rowSpacing: 9) {
                ForEach(wordGroup.words, id: \.self) { word in
                    Button {
                        toggleWord(word)
                    } label: {
                        Text(LocalizedStringKey(word))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(selectedWords.contains(word) ? .white : AppTheme.text)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(selectedWords.contains(word) ? option.tint : AppTheme.fieldBackground)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .authPanel()
    }

    private var causeStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localizedAppString("What may have caused this feeling?"))
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.text)

            TextField(localizedAppString("Add context, trigger, activity, place, person, or change in routine"), text: $cause, axis: .vertical)
                .textInputAutocapitalization(.never)
                .lineLimit(6...9)
                .padding(12)
                .background(AppTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .authPanel()
    }

    private var currentTimeText: String {
        localizedDateString(Date(), dateStyle: .none, timeStyle: .short)
    }

    private func toggleWord(_ word: String) {
        if selectedWords.contains(word) {
            selectedWords.remove(word)
        } else {
            selectedWords.insert(word)
        }
    }

    private func advance() {
        switch step {
        case .kind:
            step = .valence
        case .valence:
            selectedWords.removeAll()
            step = .words
        case .words:
            step = .cause
        case .cause:
            save()
        }
    }

    private func goBack() {
        switch step {
        case .kind:
            dismiss()
        case .valence:
            step = .kind
        case .words:
            step = .valence
        case .cause:
            step = .words
        }
    }

    private func save() {
        let sortedWords = wordGroup.words.filter { selectedWords.contains($0) }
        let kindTitle = selectedKind?.rawValue ?? "Mood"
        let valenceTitle = MoodValence.title(for: valence)
        let wordText = sortedWords.joined(separator: ", ")
        let value = "\(kindTitle): \(valenceTitle)"
        let detailLines = [
            wordText.isEmpty ? nil : "States: \(wordText)",
            cause.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : "Cause: \(cause.trimmingCharacters(in: .whitespacesAndNewlines))"
        ].compactMap { $0 }

        let entry = HealthLogEntry(
            id: UUID(),
            type: .quickLog,
            categoryID: option.id,
            title: option.title,
            timestamp: Date(),
            severity: valence,
            value: value,
            comments: detailLines.joined(separator: "\n")
        )
        onSave(entry)
        dismiss()
    }
}

struct MoodValenceSlider: View {
    @Binding var value: Int
    let tint: Color

    private let barWidth: CGFloat = 46
    private let barHeight: CGFloat = 360

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .trailing, spacing: 0) {
                ForEach(MoodValence.all.reversed()) { mood in
                    Text(LocalizedStringKey(mood.title))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(value == mood.id ? AppTheme.text : .secondary)
                        .frame(height: barHeight / 7, alignment: .center)
                }
            }

            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.84, green: 0.42, blue: 0.56),
                                Color(red: 0.96, green: 0.74, blue: 0.48),
                                Color(red: 0.91, green: 0.91, blue: 0.78),
                                Color(red: 0.52, green: 0.78, blue: 0.63)
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: barWidth, height: barHeight)

                Circle()
                    .fill(.white)
                    .frame(width: 54, height: 54)
                    .shadow(color: Color.black.opacity(0.16), radius: 10, x: 0, y: 5)
                    .overlay {
                        Circle()
                            .stroke(tint, lineWidth: 4)
                    }
                    .offset(y: thumbOffset)
            }
            .frame(width: 74, height: barHeight)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        updateValue(from: gesture.location.y)
                    }
            )
        }
        .frame(maxWidth: .infinity)
    }

    private var thumbOffset: CGFloat {
        let segment = barHeight / 6
        let bottomOffset = CGFloat(value - 1) * segment
        return -bottomOffset
    }

    private func updateValue(from yLocation: CGFloat) {
        let clampedY = min(max(yLocation, 0), barHeight)
        let relativeFromBottom = 1 - (clampedY / barHeight)
        let newValue = Int((relativeFromBottom * 6).rounded()) + 1
        value = min(max(newValue, 1), 7)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var rowSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = rows(for: subviews, proposalWidth: proposal.width ?? 320)
        return CGSize(
            width: proposal.width ?? rows.map(\.width).max() ?? 0,
            height: rows.map(\.height).reduce(0, +) + CGFloat(max(rows.count - 1, 0)) * rowSpacing
        )
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = rows(for: subviews, proposalWidth: bounds.width)
        var y = bounds.minY

        for row in rows {
            var x = bounds.minX

            for item in row.items {
                item.subview.place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(item.size)
                )
                x += item.size.width + spacing
            }

            y += row.height + rowSpacing
        }
    }

    private func rows(for subviews: Subviews, proposalWidth: CGFloat) -> [FlowLayoutRow] {
        var rows: [FlowLayoutRow] = []
        var currentItems: [FlowLayoutItem] = []
        var currentWidth: CGFloat = 0
        var currentHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let itemWidth = currentItems.isEmpty ? size.width : size.width + spacing

            if currentWidth + itemWidth > proposalWidth, !currentItems.isEmpty {
                rows.append(FlowLayoutRow(items: currentItems, width: currentWidth, height: currentHeight))
                currentItems = []
                currentWidth = 0
                currentHeight = 0
            }

            currentItems.append(FlowLayoutItem(subview: subview, size: size))
            currentWidth += currentItems.count == 1 ? size.width : size.width + spacing
            currentHeight = max(currentHeight, size.height)
        }

        if !currentItems.isEmpty {
            rows.append(FlowLayoutRow(items: currentItems, width: currentWidth, height: currentHeight))
        }

        return rows
    }
}

struct FlowLayoutRow {
    let items: [FlowLayoutItem]
    let width: CGFloat
    let height: CGFloat
}

struct FlowLayoutItem {
    let subview: LayoutSubview
    let size: CGSize
}

struct MedicineLogSheet: View {
    @Environment(\.dismiss) private var dismiss

    let option: QuickLogOption
    @Binding var medications: [MedicationSchedule]
    @Binding var medicationCheckState: MedicationCheckState
    let onSave: (HealthLogEntry) -> Void

    @State private var checkedMedicationIDs: Set<String> = []
    @State private var editingMedication: MedicationSchedule?
    @State private var isMedicineManagerPresented = false

    private var today: MedicationWeekday {
        MedicationWeekday.today()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(todayDateTitle)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(AppTheme.panel)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        medicationChecklistSection
                    }
                    .padding(18)
                }
                StickyBottomSaveButton(title: "Save Log", tint: AppTheme.accent) {
                    save()
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(localizedAppString("Cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .principal) {
                    ModalToolbarTitle(icon: option.icon, title: option.title, tint: option.tint)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isMedicineManagerPresented = true
                    } label: {
                        Text(localizedAppString("Edit"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.accent)
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
        .sheet(isPresented: $isMedicineManagerPresented) {
            MedicineManagerSheet(
                medications: $medications,
                tint: option.tint,
                onAdd: {
                    openMedicationEditor(MedicationSchedule.empty())
                },
                onEdit: { medication in
                    openMedicationEditor(medication)
                },
                onDelete: { medication in
                    deleteMedication(medication)
                }
            )
        }
    }

    private var todayDateTitle: String {
        localizedDateString(Date(), dateStyle: .full, timeStyle: .none)
    }

    private var medicationChecklistSection: some View {
        let rows = checklistRows

        return VStack(alignment: .leading, spacing: 12) {
            Text(localizedAppString("Today's Medicines"))
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.text)

            if rows.isEmpty {
                Text(localizedAppString("None"))
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

    private var checklistRows: [MedicationChecklistItem] {
        medications.flatMap { medication -> [MedicationChecklistItem] in
            switch medication.mode {
            case .daily:
                return medication.dailyTimes.map { time in
                    MedicationChecklistItem(
                        id: MedicationChecklistIdentifier.id(for: medication, day: nil, time: time),
                        medication: medication,
                        time: time,
                        dose: medication.dose(for: nil, time: time),
                        timeText: medication.clockTimeText(for: nil, time: time),
                        sortMinutes: medication.clockTimeMinutes(for: nil, time: time)
                    )
                }
            case .intervalDays:
                guard isMedicationDueToday(medication) else { return [] }
                return medication.dailyTimes.map { time in
                    MedicationChecklistItem(
                        id: MedicationChecklistIdentifier.id(for: medication, day: nil, time: time),
                        medication: medication,
                        time: time,
                        dose: medication.dose(for: nil, time: time),
                        timeText: medication.clockTimeText(for: nil, time: time),
                        sortMinutes: medication.clockTimeMinutes(for: nil, time: time)
                    )
                }
            case .weekly:
                guard medication.weeklyDays.contains(today) else { return [] }
                return medication.weeklyTimes.map { time in
                    MedicationChecklistItem(
                        id: MedicationChecklistIdentifier.id(for: medication, day: today, time: time),
                        medication: medication,
                        time: time,
                        dose: medication.dose(for: today, time: time),
                        timeText: medication.clockTimeText(for: today, time: time),
                        sortMinutes: medication.clockTimeMinutes(for: today, time: time)
                    )
                }
            }
        }
        .sorted { first, second in
            if first.sortMinutes == second.sortMinutes {
                return first.medication.displayName.localizedCaseInsensitiveCompare(second.medication.displayName) == .orderedAscending
            }

            return first.sortMinutes < second.sortMinutes
        }
    }

    private func isMedicationDueToday(_ medication: MedicationSchedule, calendar: Calendar = .current) -> Bool {
        let interval = max(1, medication.intervalDays)
        let start = calendar.startOfDay(for: medication.startDate)
        let todayDate = calendar.startOfDay(for: Date())
        guard let days = calendar.dateComponents([.day], from: start, to: todayDate).day, days >= 0 else {
            return false
        }

        return days % interval == 0
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

    private func deleteMedication(_ medication: MedicationSchedule) {
        medications.removeAll { $0.id == medication.id }
        checkedMedicationIDs.formIntersection(currentChecklistRowIDs)
        persistCheckedMedicationIDs()
    }

    private func openMedicationEditor(_ medication: MedicationSchedule) {
        isMedicineManagerPresented = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            editingMedication = medication
        }
    }

    private func save() {
        persistCheckedMedicationIDs()

        let allRows = checklistRows
        let checkedRows = allRows.filter { checkedMedicationIDs.contains($0.id) }
        let checkedSummary = checkedRows.isEmpty
            ? "No medicine checked"
            : checkedRows.map { "\($0.timeText): \($0.medication.displayName)\($0.dose.isEmpty ? "" : " \($0.dose)")" }.joined(separator: "\n")

        let sectionSummary = allRows.map { row in
            let checkedMark = checkedMedicationIDs.contains(row.id) ? "Checked" : "Not checked"
            let doseText = row.dose.isEmpty ? "" : " \(row.dose)"
            return "\(row.timeText): \(checkedMark) - \(row.medication.displayName)\(doseText)"
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
        Set(checklistRows.map(\.id))
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
    let timeText: String
    let sortMinutes: Int
}

func localizedMedicineDoseText(_ text: String) -> String {
    var localizedText = text
    let terms = [
        "Tablet(s)",
        "Capsule(s)",
        "Drop(s)",
        "Dose",
        "Round Tablet",
        "Capsule",
        "Liquid",
        "Injection",
        "Drops",
        "Other"
    ]

    for term in terms {
        localizedText = localizedText.replacingOccurrences(of: term, with: localizedAppString(term))
    }

    return localizedText
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

                Text(row.timeText)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(tint)
                    .frame(width: 72, alignment: .leading)

                VStack(alignment: .leading, spacing: 3) {
                    Text(row.medication.displayName.isEmpty ? localizedAppString("Unnamed Medicine") : row.medication.displayName)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppTheme.text)

                    if !row.dose.isEmpty {
                        Text(localizedMedicineDoseText(row.dose))
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

struct MedicineManagerSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var medications: [MedicationSchedule]
    let tint: Color
    let onAdd: () -> Void
    let onEdit: (MedicationSchedule) -> Void
    let onDelete: (MedicationSchedule) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    Button {
                        onAdd()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "plus")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(tint)
                                .frame(width: 30)

                            Text(localizedAppString("Add New"))
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(AppTheme.text)

                            Spacer()
                        }
                        .padding(14)
                        .background(AppTheme.panel)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    if medications.isEmpty {
                        Text(localizedAppString("None"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(AppTheme.panel)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    } else {
                        ForEach(medications) { medication in
                            HStack(spacing: 12) {
                                Button {
                                    onEdit(medication)
                                } label: {
                                    Text(medication.displayName.isEmpty ? localizedAppString("Unnamed Medicine") : medication.displayName)
                                        .font(.headline.weight(.semibold))
                                        .foregroundStyle(AppTheme.text)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)

                                Button(role: .destructive) {
                                    onDelete(medication)
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(Color(red: 0.86, green: 0.22, blue: 0.24))
                                        .frame(width: 38, height: 38)
                                        .background(Color(red: 0.86, green: 0.22, blue: 0.24).opacity(0.1))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(14)
                            .background(AppTheme.panel)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                }
                .padding(18)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(localizedAppString("Done")) {
                        dismiss()
                    }
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct MedicationEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: (MedicationSchedule) -> Void

    @State private var draft: MedicationSchedule

    init(medication: MedicationSchedule, onSave: @escaping (MedicationSchedule) -> Void) {
        self.onSave = onSave
        var initialMedication = medication
        if initialMedication.amount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let existingDose = initialMedication.doses.values.first?.trimmingCharacters(in: .whitespacesAndNewlines),
           !existingDose.isEmpty {
            initialMedication.amount = existingDose
        }
        self._draft = State(initialValue: initialMedication)
    }

    private var canSave: Bool {
        let hasName = !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        switch draft.mode {
        case .daily, .intervalDays:
            return hasName && !draft.dailyTimes.isEmpty
        case .weekly:
            return hasName && !draft.weeklyDays.isEmpty && !draft.weeklyTimes.isEmpty
        }
    }

    private var doseInputs: [MedicationDoseInput] {
        switch draft.mode {
        case .daily, .intervalDays:
            return sortedTimes(draft.dailyTimes).enumerated().map { index, time in
                MedicationDoseInput(
                    id: draft.doseKey(day: nil, time: time),
                    label: "Dose \(index + 1)",
                    time: time
                )
            }
        case .weekly:
            return sortedDays(draft.weeklyDays).flatMap { day in
                sortedTimes(draft.weeklyTimes).enumerated().map { index, time in
                    MedicationDoseInput(
                        id: draft.doseKey(day: day, time: time),
                        label: "\(day.shortTitle) Dose \(index + 1)",
                        time: time
                    )
                }
            }
        }
    }

    private var timePickerInputs: [MedicationDoseInput] {
        switch draft.mode {
        case .daily, .intervalDays:
            return doseInputs
        case .weekly:
            return sortedTimes(draft.weeklyTimes).enumerated().map { index, time in
                MedicationDoseInput(
                    id: weeklyTemplateKey(for: time),
                    label: "Dose \(index + 1)",
                    time: time
                )
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

    private let medicineTypes = [
        "Round Tablet",
        "Capsule",
        "Liquid",
        "Injection",
        "Drops",
        "Other"
    ]

    private let medicineUnits = [
        "Tablet(s)",
        "Capsule(s)",
        "mL",
        "mg",
        "g",
        "Drop(s)",
        "Dose"
    ]

    private let durationOptions = [
        "Until stopped",
        "7 days",
        "14 days",
        "30 days",
        "90 days",
        "As needed"
    ]

    private let doseFrequencyOptions = [
        "Once a day",
        "Twice a day",
        "Three times a day",
        "Multiple times a day"
    ]

    private var selectedDoseSlots: [MedicationDayTime] {
        switch draft.mode {
        case .daily, .intervalDays:
            return draft.dailyTimes
        case .weekly:
            return draft.weeklyTimes
        }
    }

    private var medicationTypeSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 24) {
                Button {
                    cycleMedicineType(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppTheme.text)
                        .frame(width: 42, height: 42)
                        .background(AppTheme.fieldBackground)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Spacer()

                VStack(spacing: 8) {
                    Image(systemName: medicineTypeIcon)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 82, height: 82)
                        .background(AppTheme.accent)
                        .clipShape(Circle())

                    Text(LocalizedStringKey(draft.medicineType))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.accent)
                }

                Spacer()

                Button {
                    cycleMedicineType(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppTheme.text)
                        .frame(width: 42, height: 42)
                        .background(AppTheme.fieldBackground)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 12)
        }
    }

    private var weeklyDayPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
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
        }
        .padding(12)
        .background(MedicationFormStyle.detailBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var whatTimeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            MedicationFormMenu(
                title: "What Time?",
                value: doseFrequencyTitle,
                options: doseFrequencyOptions
            ) { frequency in
                applyDoseFrequency(frequency)
            }

            if timePickerInputs.isEmpty {
                EmptyView()
            } else {
                ForEach(timePickerInputs) { input in
                    HStack {
                        Text(LocalizedStringKey(input.label))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.text)

                        Spacer()

                        DatePicker(
                            input.label,
                            selection: medicationTimeBinding(for: input),
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                    }
                    .padding(12)
                    .background(MedicationFormStyle.detailBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }

    private var medicineTypeIcon: String {
        switch draft.medicineType {
        case "Liquid":
            return "drop.fill"
        case "Injection":
            return "cross.case.fill"
        case "Drops":
            return "drop.fill"
        default:
            return "pills.fill"
        }
    }

    private var formattedDoseText: String {
        let amount = draft.amount.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !amount.isEmpty else { return "" }
        return "\(amount) \(draft.unit)"
    }

    private var howOftenTitle: String {
        switch draft.mode {
        case .intervalDays:
            return "Every X days"
        default:
            return draft.mode.title
        }
    }

    private var doseFrequencyTitle: String {
        switch selectedDoseSlots.count {
        case 1:
            return "Once a day"
        case 2:
            return "Twice a day"
        case 3:
            return "Three times a day"
        default:
            return "What Time?"
        }
    }

    private func applyDoseFrequency(_ frequency: String) {
        switch frequency {
        case "Once a day":
            setDoseSlots([.morning])
        case "Twice a day":
            setDoseSlots([.morning, .evening])
        case "Three times a day", "Multiple times a day":
            setDoseSlots([.morning, .noon, .evening])
        default:
            break
        }
    }

    private func setDoseSlots(_ times: [MedicationDayTime]) {
        switch draft.mode {
        case .daily, .intervalDays:
            let removedTimes = draft.dailyTimes.filter { !times.contains($0) }
            draft.dailyTimes = times

            for time in times {
                let key = draft.doseKey(day: nil, time: time)
                draft.clockTimes[key] = draft.clockTimes[key, default: time.defaultClockTime]
            }

            for time in removedTimes {
                let key = draft.doseKey(day: nil, time: time)
                draft.doses.removeValue(forKey: key)
                draft.clockTimes.removeValue(forKey: key)
            }
        case .weekly:
            let removedTimes = draft.weeklyTimes.filter { !times.contains($0) }
            draft.weeklyTimes = times

            for time in times {
                let templateKey = weeklyTemplateKey(for: time)
                draft.clockTimes[templateKey] = draft.clockTimes[templateKey, default: time.defaultClockTime]
            }

            for day in draft.weeklyDays {
                for time in times {
                    let key = draft.doseKey(day: day, time: time)
                    draft.clockTimes[key] = draft.clockTimes[key]
                        ?? draft.clockTimes[weeklyTemplateKey(for: time)]
                        ?? time.defaultClockTime
                }
            }

            for day in MedicationWeekday.allCases {
                for time in removedTimes {
                    let key = draft.doseKey(day: day, time: time)
                    draft.doses.removeValue(forKey: key)
                    draft.clockTimes.removeValue(forKey: key)
                }
            }

            for time in removedTimes {
                draft.clockTimes.removeValue(forKey: weeklyTemplateKey(for: time))
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        MedicationFormTextField(
                            title: "Medicine Name",
                            placeholder: "Medicine Name",
                            text: $draft.name,
                            showsClearButton: true
                        )

                        medicationTypeSelector

                        HStack(spacing: 10) {
                            MedicationFormTextField(
                                title: "Amount",
                                placeholder: "Amount",
                                text: $draft.amount,
                                keyboardType: .decimalPad,
                                showsClearButton: false
                            )

                            MedicationFormMenu(
                                title: "Unit",
                                value: draft.unit.isEmpty ? "Unit" : draft.unit,
                                options: medicineUnits
                            ) { unit in
                                draft.unit = unit
                            }
                        }

                        MedicationFormMenu(
                            title: "How often?",
                            value: howOftenTitle,
                            options: MedicationScheduleMode.allCases.map(\.title)
                        ) { title in
                            if let mode = MedicationScheduleMode.allCases.first(where: { $0.title == title }) {
                                setScheduleMode(mode)
                            }
                        }

                        if draft.mode == .intervalDays {
                            MedicationIntervalDaysField(days: intervalDaysBinding)
                        }

                        if draft.mode == .weekly {
                            weeklyDayPicker
                        }

                        whatTimeSection

                        MedicationFormMenu(
                            title: "Duration",
                            value: draft.duration.isEmpty ? "Duration" : draft.duration,
                            options: durationOptions
                        ) { duration in
                            draft.duration = duration
                        }

                        DatePicker("Start Date", selection: $draft.startDate, displayedComponents: .date)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.text)
                            .padding(12)
                            .background(MedicationFormStyle.detailBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        ZStack(alignment: .topLeading) {
                            if draft.instructions.isEmpty {
                                Text(localizedAppString("Medication Instruction (Optional)"))
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 13)
                                    .padding(.vertical, 16)
                            }

                            TextEditor(text: $draft.instructions)
                                .textInputAutocapitalization(.never)
                                .frame(minHeight: 88)
                                .scrollContentBackground(.hidden)
                                .padding(8)
                        }
                        .background(MedicationFormStyle.detailBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(18)
                }

                StickyBottomSaveButton(title: "Save", tint: AppTheme.accent, isDisabled: !canSave) {
                    save()
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.text)
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text(LocalizedStringKey(draft.legalName.isEmpty ? "Add Medication" : "Edit Medication"))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppTheme.text)
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

    private var intervalDaysBinding: Binding<String> {
        Binding {
            "\(max(1, draft.intervalDays))"
        } set: { newValue in
            let digits = newValue.filter(\.isNumber)
            draft.intervalDays = max(1, min(365, Int(digits) ?? 1))
        }
    }

    private func doseBinding(for key: String) -> Binding<String> {
        Binding {
            draft.doses[key, default: ""]
        } set: { newValue in
            draft.doses[key] = newValue
        }
    }

    private func timeBinding(for key: String, fallback: MedicationDayTime) -> Binding<Date> {
        Binding {
            MedicationTimeFormatting.date(from: draft.clockTimes[key, default: fallback.defaultClockTime])
        } set: { newValue in
            draft.clockTimes[key] = MedicationTimeFormatting.storedTime(from: newValue)
        }
    }

    private func medicationTimeBinding(for input: MedicationDoseInput) -> Binding<Date> {
        switch draft.mode {
        case .daily, .intervalDays:
            return timeBinding(for: input.id, fallback: input.time)
        case .weekly:
            return weeklyTimeBinding(for: input.time)
        }
    }

    private func weeklyTemplateKey(for time: MedicationDayTime) -> String {
        "weeklyTemplate.\(time.rawValue)"
    }

    private func weeklyTimeBinding(for time: MedicationDayTime) -> Binding<Date> {
        Binding {
            let firstSelectedDayKey = sortedDays(draft.weeklyDays)
                .first
                .map { draft.doseKey(day: $0, time: time) }
            let storedTime = firstSelectedDayKey.flatMap { draft.clockTimes[$0] }
                ?? draft.clockTimes[weeklyTemplateKey(for: time)]
                ?? time.defaultClockTime
            return MedicationTimeFormatting.date(from: storedTime)
        } set: { newValue in
            let storedTime = MedicationTimeFormatting.storedTime(from: newValue)
            draft.clockTimes[weeklyTemplateKey(for: time)] = storedTime

            for day in draft.weeklyDays {
                draft.clockTimes[draft.doseKey(day: day, time: time)] = storedTime
            }
        }
    }

    private func cycleMedicineType(by offset: Int) {
        guard let currentIndex = medicineTypes.firstIndex(of: draft.medicineType) else {
            draft.medicineType = medicineTypes.first ?? "Round Tablet"
            return
        }

        let newIndex = (currentIndex + offset + medicineTypes.count) % medicineTypes.count
        draft.medicineType = medicineTypes[newIndex]
    }

    private func setScheduleMode(_ mode: MedicationScheduleMode) {
        guard draft.mode != mode else { return }

        draft.mode = mode

        switch mode {
        case .daily, .intervalDays:
            if draft.dailyTimes.isEmpty {
                draft.dailyTimes = draft.weeklyTimes.isEmpty ? [.morning] : draft.weeklyTimes
            }
            draft.weeklyDays.removeAll()
            draft.weeklyTimes.removeAll()
            draft.doses = draft.doses.filter { !$0.key.contains(".") }
            draft.clockTimes = draft.clockTimes.filter { !$0.key.contains(".") }
        case .weekly:
            if draft.weeklyTimes.isEmpty {
                draft.weeklyTimes = draft.dailyTimes.isEmpty ? [.morning] : draft.dailyTimes
            }
            draft.dailyTimes.removeAll()
            draft.doses = draft.doses.filter { $0.key.contains(".") }
            draft.clockTimes = draft.clockTimes.filter { $0.key.contains(".") }
        }
    }

    private func copyFirstDoseToAll() {
        guard let dose = firstEnteredDose else { return }

        for input in doseInputs {
            draft.doses[input.id] = dose
        }
    }

    private func toggleDailyTime(_ time: MedicationDayTime) {
        let key = draft.doseKey(day: nil, time: time)

        if let index = draft.dailyTimes.firstIndex(of: time) {
            draft.dailyTimes.remove(at: index)
            draft.doses.removeValue(forKey: key)
            draft.clockTimes.removeValue(forKey: key)
        } else {
            draft.dailyTimes.append(time)
            draft.clockTimes[key] = draft.clockTimes[key, default: time.defaultClockTime]
        }
    }

    private func toggleWeeklyTime(_ time: MedicationDayTime) {
        if let index = draft.weeklyTimes.firstIndex(of: time) {
            draft.weeklyTimes.remove(at: index)

            for day in MedicationWeekday.allCases {
                let key = draft.doseKey(day: day, time: time)
                draft.doses.removeValue(forKey: key)
                draft.clockTimes.removeValue(forKey: key)
            }
        } else {
            draft.weeklyTimes.append(time)

            for day in draft.weeklyDays {
                let key = draft.doseKey(day: day, time: time)
                draft.clockTimes[key] = draft.clockTimes[key]
                    ?? draft.clockTimes[weeklyTemplateKey(for: time)]
                    ?? time.defaultClockTime
            }
        }
    }

    private func toggleWeeklyDay(_ day: MedicationWeekday) {
        if let index = draft.weeklyDays.firstIndex(of: day) {
            draft.weeklyDays.remove(at: index)

            for time in MedicationDayTime.allCases {
                let key = draft.doseKey(day: day, time: time)
                draft.doses.removeValue(forKey: key)
                draft.clockTimes.removeValue(forKey: key)
            }
        } else {
            draft.weeklyDays.append(day)

            for time in draft.weeklyTimes {
                let key = draft.doseKey(day: day, time: time)
                draft.clockTimes[key] = draft.clockTimes[key]
                    ?? draft.clockTimes[weeklyTemplateKey(for: time)]
                    ?? time.defaultClockTime
            }
        }
    }

    private func save() {
        var saved = draft
        saved.name = saved.name.trimmingCharacters(in: .whitespacesAndNewlines)
        saved.nickname = ""
        saved.amount = saved.amount.trimmingCharacters(in: .whitespacesAndNewlines)
        saved.unit = saved.unit.trimmingCharacters(in: .whitespacesAndNewlines)
        saved.duration = saved.duration.trimmingCharacters(in: .whitespacesAndNewlines)
        saved.prescribingDoctor = ""
        saved.instructions = saved.instructions.trimmingCharacters(in: .whitespacesAndNewlines)

        let activeDoseKeys = Set(doseInputs.map(\.id))
        let commonDose = formattedDoseText
        saved.doses = activeDoseKeys.reduce(into: [:]) { result, key in
            if !commonDose.isEmpty {
                result[key] = commonDose
            } else {
                let value = saved.doses[key, default: ""].trimmingCharacters(in: .whitespacesAndNewlines)
                if !value.isEmpty {
                    result[key] = value
                }
            }
        }
        saved.clockTimes = doseInputs.reduce(into: [:]) { result, input in
            result[input.id] = saved.clockTimes[input.id]
                ?? saved.clockTimes[weeklyTemplateKey(for: input.time)]
                ?? input.time.defaultClockTime
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
    let time: MedicationDayTime
}

enum MedicationFormStyle {
    static let background = Color(red: 0.88, green: 0.95, blue: 0.93)
    static let detailBackground = AppTheme.panel
    static let border = Color(red: 0.80, green: 0.90, blue: 0.88)
}

struct MedicationFormTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var showsClearButton: Bool

    var body: some View {
        HStack(spacing: 8) {
            TextField(localizedAppString(placeholder), text: $text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.never)
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppTheme.text)

            if showsClearButton && !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(AppTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(MedicationFormStyle.border.opacity(0.55), lineWidth: 1)
        }
    }
}

struct MedicationFormMenu: View {
    let title: String
    let value: String
    let options: [String]
    let onSelect: (String) -> Void

    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(localizedAppString(option)) {
                    onSelect(option)
                }
            }
        } label: {
            HStack {
                Text(value.isEmpty ? localizedAppString(title) : localizedAppString(value))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(MedicationFormStyle.background)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(MedicationFormStyle.border.opacity(0.55), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

struct MedicationIntervalDaysField: View {
    @Binding var days: String

    var body: some View {
        HStack(spacing: 12) {
            Text(localizedAppString("Every how many days?"))
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppTheme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer()

            TextField("2", text: $days)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.text)
                .frame(width: 58)
                .padding(.vertical, 8)
                .background(Color(red: 0.96, green: 0.98, blue: 0.97))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text(localizedAppString("days"))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(MedicationFormStyle.detailBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(MedicationFormStyle.border.opacity(0.55), lineWidth: 1)
        }
    }
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

                Text(LocalizedStringKey(title))
                    .font(.caption.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .foregroundStyle(isSelected ? .white : AppTheme.text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
            .background(isSelected ? AppTheme.accent : MedicationFormStyle.background)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct PainLogEntrySheet: View {
    @Environment(\.dismiss) private var dismiss

    let option: QuickLogOption
    let onSave: (HealthLogEntry) -> Void

    @State private var severity = 3.0
    @State private var painPoints: [PainPoint] = []
    @State private var shortComment = ""
    @State private var indicators = ""

    private var displayLocation: String {
        painPoints.isEmpty ? localizedAppString("Tap the body to add a pain dot") : String(format: localizedAppString("%d pain location(s)"), painPoints.count)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 16) {
                            PainBodySelector(
                                painPoints: $painPoints,
                                tint: option.tint
                            )

                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(localizedAppString("Severity")): \(Int(severity))/5")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.text)

                            Slider(value: $severity, in: 1...5, step: 1)
                                .tint(option.tint)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text(localizedAppString("Short Comment"))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.text)

                            TextField(localizedAppString("What happened or what helped?"), text: $shortComment, axis: .vertical)
                                .textInputAutocapitalization(.never)
                                .lineLimit(3...5)
                                .padding(12)
                                .background(AppTheme.fieldBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text(localizedAppString("Indicators"))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.text)

                            TextField(localizedAppString("Crying, holding head, aggression, guarding, limping"), text: $indicators, axis: .vertical)
                                .textInputAutocapitalization(.never)
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
                StickyBottomSaveButton(title: "Save Log", tint: AppTheme.accent) {
                    save()
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(localizedAppString("Cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .principal) {
                    ModalToolbarTitle(icon: option.icon, title: option.title, tint: option.tint)
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
            timestamp: Date(),
            severity: Int(severity),
            value: savedLocation,
            comments: notes
        )
        onSave(entry)
        dismiss()
    }
}

enum SkinSeverityLevel: String, CaseIterable, Identifiable {
    case mild = "Mild"
    case moderate = "Moderate"
    case severe = "Severe"

    var id: String { rawValue }

    var score: Int {
        switch self {
        case .mild:
            return 1
        case .moderate:
            return 3
        case .severe:
            return 5
        }
    }

    var description: String {
        switch self {
        case .mild:
            return "Localized redness, slight itch, isolated spots"
        case .moderate:
            return "Spreading hives, widespread rash, significant scratching"
        case .severe:
            return "Rapidly spreading, swelling of face/lips"
        }
    }

    var color: Color {
        switch self {
        case .mild:
            return Color(red: 0.43, green: 0.77, blue: 0.52)
        case .moderate:
            return Color(red: 0.95, green: 0.69, blue: 0.22)
        case .severe:
            return Color(red: 0.90, green: 0.25, blue: 0.25)
        }
    }
}

struct SkinLogEntrySheet: View {
    @Environment(\.dismiss) private var dismiss

    let option: QuickLogOption
    let onSave: (HealthLogEntry) -> Void

    @State private var timestamp = Date()
    @State private var selectedMealPhoto: PhotosPickerItem?
    @State private var isCameraPickerPresented = false
    @State private var photoData = Data()
    @State private var selectedSeverity: SkinSeverityLevel?
    @State private var selectedLocations: Set<String> = []
    @State private var selectedTriggers: Set<String> = []
    @State private var selectedSymptoms: Set<String> = []

    private let locationOptions = [
        "Face/Neck",
        "Torso",
        "Arms",
        "Legs",
        "Full Body"
    ]

    private let triggerOptions = [
        "New Food",
        "Medication",
        "Environmental/Outdoor",
        "Detergent/Soap",
        "Unknown"
    ]

    private let symptomOptions = [
        "Itching/Scratching",
        "Heat/Feverish skin",
        "Swelling",
        "Irritation/Crying"
    ]

    private var canSave: Bool {
        selectedSeverity != nil
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        photoCard

                        timestampCard

                        severityCard

                        if selectedSeverity == .severe {
                            severeReminder
                        }

                        skinChipSection(
                            icon: "mappin.and.ellipse",
                            title: "Location",
                            options: locationOptions,
                            selection: $selectedLocations
                        )

                        skinChipSection(
                            icon: "questionmark.circle",
                            title: "Suspected Trigger",
                            options: triggerOptions,
                            selection: $selectedTriggers
                        )

                        skinChipSection(
                            icon: "tag.fill",
                            title: "Symptom Tags",
                            options: symptomOptions,
                            selection: $selectedSymptoms
                        )
                    }
                    .padding(18)
                }

                StickyBottomSaveButton(
                    title: "Save Log",
                    tint: AppTheme.accent,
                    isDisabled: !canSave
                ) {
                    save()
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(localizedAppString("Cancel")) {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.accent)
                }

                ToolbarItem(placement: .principal) {
                    ModalToolbarTitle(icon: option.icon, title: option.title, tint: option.tint)
                }
            }
            .task(id: selectedMealPhoto) {
                await loadSelectedPhoto()
            }
            .fullScreenCover(isPresented: $isCameraPickerPresented) {
                CameraMealPhotoPicker { data in
                    photoData = compressedSkinPhotoData(data)
                }
                .ignoresSafeArea()
            }
        }
        .presentationDetents([.large])
    }

    private var photoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(localizedAppString("Skin Photo"), systemImage: "camera.fill")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.text)

                Spacer()
            }

            if let image = UIImage(data: photoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 170)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            HStack(spacing: 10) {
                Button {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        isCameraPickerPresented = true
                    }
                } label: {
                    Label(localizedAppString("Take Photo"), systemImage: "camera.fill")
                        .font(.subheadline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(UIImagePickerController.isSourceTypeAvailable(.camera) ? option.tint.opacity(0.16) : Color.gray.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))

                PhotosPicker(selection: $selectedMealPhoto, matching: .images) {
                    Label(localizedAppString("Upload Photo"), systemImage: "photo.on.rectangle")
                        .font(.subheadline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(option.tint.opacity(0.16))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .foregroundStyle(AppTheme.accent)
        }
        .skinSectionCard()
    }

    private var timestampCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "calendar.badge.clock")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 30, height: 30)
                .background(AppTheme.accent.opacity(0.1))
                .clipShape(Circle())

            Text(localizedAppString("Timestamp"))
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.text)

            Spacer(minLength: 4)

            DatePicker("", selection: $timestamp, displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(.compact)
                .fixedSize()

            DatePicker("", selection: $timestamp, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .datePickerStyle(.compact)
                .fixedSize()
        }
        .skinSectionCard()
    }

    private var severityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(localizedAppString("Severity Level"), systemImage: "gauge.with.dots.needle.50percent")
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.text)

            VStack(spacing: 9) {
                ForEach(SkinSeverityLevel.allCases) { severity in
                    Button {
                        selectedSeverity = selectedSeverity == severity ? nil : severity
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(severity.color)
                                .frame(width: 12, height: 12)
                                .padding(.top, 5)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(localizedAppString(severity.rawValue))
                                    .font(.subheadline.weight(.black))

                                Text(localizedAppString(severity.description))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(selectedSeverity == severity ? .white.opacity(0.86) : .secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()

                            Image(systemName: selectedSeverity == severity ? "checkmark.circle.fill" : "circle")
                                .font(.headline.weight(.bold))
                        }
                        .foregroundStyle(selectedSeverity == severity ? .white : AppTheme.text)
                        .padding(12)
                        .background(selectedSeverity == severity ? severity.color : AppTheme.fieldBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .skinSectionCard()
    }

    private var severeReminder: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 4) {
                Text(localizedAppString("Seek immediate medical attention"))
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)

                Text(localizedAppString("If prescribed, use an EpiPen and follow the emergency care plan."))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(Color(red: 0.86, green: 0.13, blue: 0.13))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func skinChipSection(
        icon: String,
        title: String,
        options: [String],
        selection: Binding<Set<String>>
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(localizedAppString(title), systemImage: icon)
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.text)

            FlowLayout(spacing: 8, rowSpacing: 8) {
                ForEach(options, id: \.self) { item in
                    CyclicVomitingOptionChip(
                        title: item,
                        isSelected: selection.wrappedValue.contains(item),
                        tint: option.tint
                    ) {
                        if selection.wrappedValue.contains(item) {
                            selection.wrappedValue.remove(item)
                        } else {
                            selection.wrappedValue.insert(item)
                        }
                    }
                }
            }
        }
        .skinSectionCard()
    }

    private func loadSelectedPhoto() async {
        guard let selectedMealPhoto else { return }

        do {
            if let data = try await selectedMealPhoto.loadTransferable(type: Data.self) {
                await MainActor.run {
                    photoData = compressedSkinPhotoData(data)
                    self.selectedMealPhoto = nil
                }
            }
        } catch {
            // Keep any already selected photo.
        }
    }

    private func compressedSkinPhotoData(_ data: Data) -> Data {
        if let image = UIImage(data: data),
           let jpegData = image.resizedForMealAnalysis(maxDimension: 900).jpegData(compressionQuality: 0.72) {
            return jpegData
        }

        return data
    }

    private func selectedText(_ values: Set<String>) -> String {
        values.isEmpty ? localizedAppString("Not selected") : values.sorted().map { localizedAppString($0) }.joined(separator: ", ")
    }

    private func save() {
        guard let selectedSeverity else { return }

        let comments = [
            "Timestamp: \(localizedDateString(timestamp, dateStyle: .medium, timeStyle: .short))",
            "Severity: \(localizedAppString(selectedSeverity.rawValue)) - \(localizedAppString(selectedSeverity.description))",
            "Locations: \(selectedText(selectedLocations))",
            "Suspected Trigger: \(selectedText(selectedTriggers))",
            "Symptoms: \(selectedText(selectedSymptoms))",
            photoData.isEmpty ? nil : "Photo attached"
        ]
        .compactMap { $0 }
        .joined(separator: "\n")

        let entry = HealthLogEntry(
            id: UUID(),
            type: .quickLog,
            categoryID: option.id,
            title: option.title,
            timestamp: timestamp,
            severity: selectedSeverity.score,
            value: localizedAppString(selectedSeverity.rawValue),
            comments: comments,
            imageData: photoData.isEmpty ? nil : photoData
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
            Text(localizedAppString("Pain Location"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.text)

            VStack(spacing: 10) {
                Picker("Body side", selection: $selectedSide) {
                    ForEach(PainBodySide.allCases) { side in
                        Text(LocalizedStringKey(side.rawValue)).tag(side)
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
                        Label(localizedAppString("Clear pain dots"), systemImage: "xmark.circle")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(AppTheme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Text(painPoints.isEmpty ? localizedAppString("Tap directly on the body to mark pain. Maximum 5 dots.") : String(format: localizedAppString("%d/5 pain dot(s) marked"), painPoints.count))
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
            Text(LocalizedStringKey(side.rawValue))
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)

            GeometryReader { proxy in
                ZStack {
                    PainLocationBodyImage(side: side)
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

                            if let tappedPoint = visiblePoints.first(where: { point in
                                abs(point.x - normalizedX) <= 0.045 && abs(point.y - normalizedY) <= 0.045
                            }) {
                                withAnimation(.spring(response: 0.24, dampingFraction: 0.74)) {
                                    painPoints.removeAll { $0.id == tappedPoint.id }
                                }
                                return
                            }

                            guard isBodyPixel(at: value.location, in: proxy.size) else { return }
                            guard painPoints.count < 5 else { return }

                            withAnimation(.spring(response: 0.24, dampingFraction: 0.74)) {
                                painPoints.append(PainPoint(side: side, x: normalizedX, y: normalizedY))
                            }
                        }
                )
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: localizedAppString("%@ body pain map"), localizedAppString(side.rawValue)))
    }

    private func imageFrame(in size: CGSize) -> CGRect {
        let aspectRatio = PainLocationBodyImageStore.aspectRatio(for: side)
        let width = min(size.width, size.height * aspectRatio)
        let height = width / aspectRatio
        return CGRect(
            x: (size.width - width) / 2,
            y: (size.height - height) / 2,
            width: width,
            height: height
        )
    }

    private func isBodyPixel(at location: CGPoint, in size: CGSize) -> Bool {
        let frame = imageFrame(in: size)
        guard frame.contains(location), frame.width > 0, frame.height > 0 else {
            return false
        }

        let imageX = (location.x - frame.minX) / frame.width
        let imageY = (location.y - frame.minY) / frame.height
        return PainLocationBodyImageStore.containsBodyPixel(side: side, x: imageX, y: imageY)
    }
}

struct PainLocationBodyImage: View {
    let side: PainBodySide

    var body: some View {
        if let image = PainLocationBodyImageStore.image(for: side) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .accessibilityHidden(true)
        } else {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 1.00, green: 0.92, blue: 0.94))
                .overlay {
                    Text(localizedAppString("Pain body image missing"))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
        }
    }
}

enum PainLocationBodyImageStore {
    private static let fallbackAspectRatio: CGFloat = 0.5

    static func image(for side: PainBodySide) -> UIImage? {
        guard let source = UIImage(named: "PainLocationBody") ?? UIImage(named: "PainLocationBody.jpg"),
              let cgImage = source.cgImage else {
            return nil
        }

        let halfWidth = cgImage.width / 2
        let cropRect = CGRect(
            x: side == .front ? 0 : halfWidth,
            y: 0,
            width: halfWidth,
            height: cgImage.height
        )

        guard let cropped = cgImage.cropping(to: cropRect) else {
            return source
        }

        return imageByRemovingWhiteBackground(from: cropped, scale: source.scale, orientation: source.imageOrientation)
    }

    static func aspectRatio(for side: PainBodySide) -> CGFloat {
        guard let image = image(for: side), image.size.height > 0 else {
            return fallbackAspectRatio
        }

        return image.size.width / image.size.height
    }

    static func containsBodyPixel(side: PainBodySide, x: CGFloat, y: CGFloat) -> Bool {
        guard let cgImage = image(for: side)?.cgImage else {
            return false
        }

        let width = cgImage.width
        let height = cgImage.height
        let clampedX = min(max(Int(round(x * CGFloat(width - 1))), 0), width - 1)
        let clampedY = min(max(Int(round(y * CGFloat(height - 1))), 0), height - 1)
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return false
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        let sampleRadius = 2
        for sampleY in max(0, clampedY - sampleRadius)...min(height - 1, clampedY + sampleRadius) {
            for sampleX in max(0, clampedX - sampleRadius)...min(width - 1, clampedX + sampleRadius) {
                let index = (sampleY * bytesPerRow) + (sampleX * bytesPerPixel)
                let red = pixels[index]
                let green = pixels[index + 1]
                let blue = pixels[index + 2]
                let alpha = pixels[index + 3]

                if alpha > 20 && (red < 248 || green < 248 || blue < 248) {
                    return true
                }
            }
        }

        return false
    }

    private static func imageByRemovingWhiteBackground(from cgImage: CGImage, scale: CGFloat, orientation: UIImage.Orientation) -> UIImage {
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return UIImage(cgImage: cgImage, scale: scale, orientation: orientation)
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var visited = [Bool](repeating: false, count: width * height)
        var queue: [(x: Int, y: Int)] = []

        func pixelOffset(x: Int, y: Int) -> Int {
            (y * bytesPerRow) + (x * bytesPerPixel)
        }

        func pixelKey(x: Int, y: Int) -> Int {
            (y * width) + x
        }

        func isBackgroundPixel(x: Int, y: Int) -> Bool {
            let index = pixelOffset(x: x, y: y)
            let red = Int(pixels[index])
            let green = Int(pixels[index + 1])
            let blue = Int(pixels[index + 2])
            let brightness = max(red, green, blue)
            let darkness = min(red, green, blue)

            return brightness >= 228 && brightness - darkness <= 18
        }

        func enqueueIfBackground(x: Int, y: Int) {
            guard x >= 0, x < width, y >= 0, y < height else { return }
            let key = pixelKey(x: x, y: y)
            guard !visited[key], isBackgroundPixel(x: x, y: y) else { return }
            visited[key] = true
            queue.append((x, y))
        }

        for x in 0..<width {
            enqueueIfBackground(x: x, y: 0)
            enqueueIfBackground(x: x, y: height - 1)
        }

        for y in 0..<height {
            enqueueIfBackground(x: 0, y: y)
            enqueueIfBackground(x: width - 1, y: y)
        }

        var head = 0
        while head < queue.count {
            let point = queue[head]
            head += 1

            pixels[pixelOffset(x: point.x, y: point.y) + 3] = 0

            enqueueIfBackground(x: point.x + 1, y: point.y)
            enqueueIfBackground(x: point.x - 1, y: point.y)
            enqueueIfBackground(x: point.x, y: point.y + 1)
            enqueueIfBackground(x: point.x, y: point.y - 1)
        }

        guard let transparentContext = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ), let transparentImage = transparentContext.makeImage() else {
            return UIImage(cgImage: cgImage, scale: scale, orientation: orientation)
        }

        return UIImage(cgImage: transparentImage, scale: scale, orientation: orientation)
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
            VStack(spacing: 0) {
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

                            Text(LocalizedStringKey(isStopped ? "Timer stopped" : (isRunning ? "Timer running" : "Timer paused")))
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
                                Text(LocalizedStringKey(isRunning ? "Pause" : "Resume"))
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
                                Text(localizedAppString("Stop"))
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
                                Text(localizedAppString("Skip"))
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
                                Text(localizedAppString("Seizure Details"))
                                    .font(.headline.weight(.bold))

                                VStack(alignment: .leading, spacing: 10) {
                                    Text(localizedAppString("Duration"))
                                        .font(.subheadline.weight(.semibold))

                                    HStack(spacing: 10) {
                                        DurationNumberField(title: localizedAppString("Minutes"), value: durationMinutesBinding)
                                        DurationNumberField(title: localizedAppString("Seconds"), value: durationSecondsBinding)
                                    }

                                    Stepper("\(localizedAppString("Fine tune")): \(durationText(elapsedSeconds))", value: $elapsedSeconds, in: 0...7200, step: 1)
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                }

                                Picker(localizedAppString("Seizure Type"), selection: $seizureType) {
                                    ForEach(seizureTypes, id: \.self) { type in
                                        Text(LocalizedStringKey(type)).tag(type)
                                    }
                                }
                                .pickerStyle(.menu)

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("\(localizedAppString("Severity")): \(Int(severity))/5")
                                        .font(.subheadline.weight(.semibold))
                                    Slider(value: $severity, in: 1...5, step: 1)
                                        .tint(option.tint)
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text(localizedAppString("Triggers"))
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(AppTheme.text)

                                    TextField(localizedAppString("Flashing lights, missed sleep, heat, illness, etc."), text: $triggers, axis: .vertical)
                                        .textInputAutocapitalization(.never)
                                        .lineLimit(3...6)
                                        .padding(12)
                                        .background(AppTheme.fieldBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text(localizedAppString("Post-event Notes"))
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(AppTheme.text)

                                    TextField(localizedAppString("Recovery, breathing, color, awareness, what helped"), text: $postEventNotes, axis: .vertical)
                                        .textInputAutocapitalization(.never)
                                        .lineLimit(4...7)
                                        .padding(12)
                                        .background(AppTheme.fieldBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }

                                Button(role: .destructive) {
                                    showingDeleteConfirmation = true
                                } label: {
                                    Text(localizedAppString("Delete"))
                                        .font(.headline.weight(.bold))
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.red.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                            }
                            .authPanel()
                        }
                    }
                    .padding(18)
                }
                StickyBottomSaveButton(title: "Save Log", tint: AppTheme.accent) {
                    save()
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(localizedAppString("Cancel")) {
                        if isStopped {
                            showingDeleteConfirmation = true
                        } else {
                            dismiss()
                        }
                    }
                }

                ToolbarItem(placement: .principal) {
                    ModalToolbarTitle(icon: option.icon, title: option.title, tint: option.tint)
                }

            }
            .confirmationDialog(
                localizedAppString("Delete this seizure timer?"),
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(localizedAppString("Delete Timer"), role: .destructive) {
                    dismiss()
                }
                Button(localizedAppString("Keep Editing"), role: .cancel) {
                }
            } message: {
                Text(localizedAppString("This timer has not been saved."))
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
            Text(localizedAppString(title))
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
                    Text(localizedAppString("No trend data yet"))
                        .font(.headline.weight(.bold))

                    Text(localizedAppString("Tap a quick-log or daily snapshot card to save the first entry."))
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
                    Text(localizedAppString("Choose quick-log buttons on the dashboard to see history here."))
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
        .onAppear {
            OrientationController.shared.lock(to: .portrait)
        }
        .onDisappear {
            OrientationController.shared.unlock()
        }
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
        } else if option.id == "medsFood" {
            NavigationLink {
                MedicineHistoryDetailView(option: option, entries: entries)
            } label: {
                medicineHistoryCard
            }
            .buttonStyle(.plain)
        } else if option.id == "mood" || option.id == "pain" || option.id == "cyclicVomiting" {
            NavigationLink {
                QuickLogHistoryDetailView(option: option, entries: entries)
            } label: {
                quickLogListCard
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
                Text(LocalizedStringKey(option.title))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.text)

                Text(String(format: localizedAppString("%d entries · Avg %@/%d"), entries.count, averageSeverityText, scaleMax))
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

    private var quickLogListCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            cardHeader

            if recentEntries.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(option.tint)
                        .frame(width: 36, height: 36)
                        .background(option.tint.opacity(0.14))
                        .clipShape(Circle())

                    Text(localizedAppString("No saved logs yet"))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.secondary)

                    Spacer()
                }
                .padding(12)
                .background(AppTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                VStack(spacing: 8) {
                    ForEach(recentEntries.reversed().prefix(3)) { entry in
                        HStack(spacing: 10) {
                            Text(entry.timestamp, format: .dateTime.month(.abbreviated).day())
                                .font(.caption.weight(.black))
                                .foregroundStyle(AppTheme.text)
                                .frame(width: 54, alignment: .leading)

                            Text(entry.value.isEmpty ? entry.title : entry.value)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(AppTheme.text)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text(entry.timestamp, format: .dateTime.hour().minute())
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(AppTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
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
                    Text(String(format: localizedAppString("%d saved logs"), entries.count))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppTheme.text)

                    Text(localizedAppString("Dates, times, duration, type, triggers, and notes"))
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

    private var medicineHistoryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            cardHeader

            if recentMedicineDays.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "checklist")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(option.tint)
                        .frame(width: 36, height: 36)
                        .background(option.tint.opacity(0.14))
                        .clipShape(Circle())

                    Text(localizedAppString("No medicine checklist saved yet"))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.secondary)

                    Spacer()
                }
                .padding(12)
                .background(AppTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                VStack(spacing: 8) {
                    ForEach(recentMedicineDays.prefix(3)) { day in
                        HStack(spacing: 10) {
                            Text(day.date, format: .dateTime.month(.abbreviated).day())
                                .font(.caption.weight(.black))
                                .foregroundStyle(AppTheme.text)
                                .frame(width: 54, alignment: .leading)

                            Text(String(format: localizedAppString("Last saved %@"), day.savedTimeText))
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text("\(day.items.count)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                                .frame(width: 28, alignment: .trailing)
                        }
                    }
                }
                .padding(12)
                .background(AppTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
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

                Text(localizedAppString("No data yet"))
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
            .chartYScale(domain: 0...scaleMax)
            .chartYAxis {
                AxisMarks(values: option.id == "mood" ? [1, 4, 7] : [1, 3, 5])
            }
            .chartXAxis(.hidden)
        }
    }

    private var averageSeverityText: String {
        averageSeverity == 0 ? "0" : String(format: "%.1f", averageSeverity)
    }

    private var scaleMax: Int {
        option.id == "mood" ? 7 : 5
    }

    private var recentMedicineDays: [MedicineHistoryDay] {
        MedicineHistoryDay.days(from: entries)
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
        .onAppear {
            OrientationController.shared.lock(to: .portrait)
        }
    }

    private func entriesFor(_ option: SnapshotOption) -> [HealthLogEntry] {
        entries
            .filter {
                option.id == "mood"
                    ? $0.type == .quickLog && $0.categoryID == "mood"
                    : $0.type == .snapshot && $0.categoryID == option.id
            }
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
                Text(LocalizedStringKey(option.title))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.text)

                Text(String(format: localizedAppString("%d entries · Avg %@/5"), entries.count, averageSeverityText))
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
                    Text(String(format: localizedAppString("%d nights tracked"), entries.count))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppTheme.text)

                    Text(localizedAppString("Sleep times and nightly duration"))
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

                Text(localizedAppString("No data yet"))
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

    @State private var selectedPeriod: SleepHistoryPeriod = .week
    @State private var selectedSleepRecordID: UUID?

    private var sleepRecords: [SleepTrackerRecord] {
        entries
            .compactMap(SleepTrackerRecord.init(entry:))
            .sorted { $0.date < $1.date }
    }

    private var anchorDate: Date {
        Date()
    }

    private var periodRecords: [SleepTrackerRecord] {
        sleepRecords.filter { selectedPeriod.contains($0.date, relativeTo: anchorDate) }
    }

    private var averageMinutes: Int {
        guard !periodRecords.isEmpty else { return 0 }
        return periodRecords.reduce(0) { $0 + $1.durationMinutes } / periodRecords.count
    }

    private var selectedSleepRecord: SleepTrackerRecord? {
        guard let selectedSleepRecordID else { return nil }
        return periodRecords.first { $0.id == selectedSleepRecordID }
    }

    private var dateRangeText: String {
        selectedPeriod.rangeText(relativeTo: anchorDate)
    }

    private var headerLabel: String {
        guard let selectedSleepRecord else {
            return localizedAppString("AVG. TIME IN BED")
        }

        let wakeText = selectedSleepRecord.wakingCount == 1 ? localizedAppString("1 wake-up") : String(format: localizedAppString("%d wake-ups"), selectedSleepRecord.wakingCount)
        return "\(localizedAppString(selectedSleepRecord.qualityTitle)) · \(wakeText)"
    }

    private var headerValue: String {
        if let selectedSleepRecord {
            return selectedSleepRecord.durationText
        }

        return SleepTrackerRecord.durationText(minutes: averageMinutes)
    }

    private var headerDateText: String {
        if let selectedSleepRecord {
            return localizedDateString(selectedSleepRecord.date, dateStyle: .medium, timeStyle: .none)
        }

        return dateRangeText
    }

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
                .onTapGesture {
                    clearSleepSelection()
                }

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if sleepRecords.isEmpty {
                        Text(localizedAppString("No Sleep & Rest entries yet."))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .authPanel()
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            Picker(localizedAppString("Sleep range"), selection: $selectedPeriod) {
                                ForEach(SleepHistoryPeriod.allCases) { period in
                                    Text(localizedAppString(period.shortTitle)).tag(period)
                                }
                            }
                            .pickerStyle(.segmented)
                            .tint(option.tint)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(option.tint)
                                        .frame(width: 8, height: 8)

                                    Text(headerLabel)
                                        .font(.caption.weight(.black))
                                        .foregroundStyle(.secondary)
                                }

                                Text(headerValue)
                                    .font(.system(size: 34, weight: .black, design: .rounded))
                                    .foregroundStyle(AppTheme.text)

                                Text(headerDateText)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }

                            if periodRecords.isEmpty {
                                Text(localizedAppString("No Sleep & Rest entries for this period."))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .background(AppTheme.fieldBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            } else {
                                SleepVerticalBarChart(
                                    records: periodRecords,
                                    period: selectedPeriod,
                                    anchorDate: anchorDate,
                                    selectedRecordID: selectedSleepRecordID,
                                    tint: option.tint
                                ) { item in
                                    DispatchQueue.main.async {
                                        selectedSleepRecordID = item.recordID
                                    }
                                } onClearSelection: {
                                    clearSleepSelection()
                                }
                                .frame(height: 330)
                            }
                        }
                        .authPanel()
                    }
                }
                .padding(18)
            }
            .simultaneousGesture(
                TapGesture().onEnded {
                    clearSleepSelection()
                }
            )
        }
        .navigationTitle(localizedAppString("Sleep & Rest"))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedPeriod) { _, _ in
            clearSleepSelection()
        }
    }

    private func clearSleepSelection() {
        selectedSleepRecordID = nil
    }
}

enum SleepHistoryPeriod: String, CaseIterable, Identifiable {
    case day
    case week
    case month
    case sixMonths

    var id: String { rawValue }

    var shortTitle: String {
        switch self {
        case .day:
            return "D"
        case .week:
            return "W"
        case .month:
            return "M"
        case .sixMonths:
            return "6M"
        }
    }

    func contains(_ date: Date, relativeTo anchorDate: Date) -> Bool {
        let calendar = Calendar.current
        let anchorEndOfDay = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: calendar.startOfDay(for: anchorDate)) ?? anchorDate
        switch self {
        case .day:
            return calendar.isDate(date, inSameDayAs: anchorDate)
        case .week:
            guard let startDate = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: anchorDate)) else {
                return false
            }
            return date >= startDate && date <= anchorEndOfDay
        case .month:
            guard let startDate = calendar.date(byAdding: .day, value: -29, to: calendar.startOfDay(for: anchorDate)) else {
                return false
            }
            return date >= startDate && date <= anchorEndOfDay
        case .sixMonths:
            guard let startDate = calendar.date(byAdding: .month, value: -5, to: calendar.startOfDay(for: anchorDate)) else {
                return false
            }
            return date >= startDate && date <= anchorEndOfDay
        }
    }

    func rangeText(relativeTo anchorDate: Date) -> String {
        let calendar = Calendar.current
        let startDate: Date
        switch self {
        case .day:
            startDate = anchorDate
        case .week:
            startDate = calendar.date(byAdding: .day, value: -6, to: anchorDate) ?? anchorDate
        case .month:
            startDate = calendar.date(byAdding: .day, value: -29, to: anchorDate) ?? anchorDate
        case .sixMonths:
            startDate = calendar.date(byAdding: .month, value: -5, to: anchorDate) ?? anchorDate
        }

        if calendar.isDate(startDate, inSameDayAs: anchorDate) {
            return localizedDateString(anchorDate, dateStyle: .medium, timeStyle: .none)
        }

        return "\(localizedDateFormatString(startDate, format: "MMM d"))–\(localizedDateString(anchorDate, dateStyle: .medium, timeStyle: .none))"
    }
}

struct SleepVerticalBarChart: View {
    let records: [SleepTrackerRecord]
    let period: SleepHistoryPeriod
    let anchorDate: Date
    let selectedRecordID: UUID?
    let tint: Color
    let onSelect: (SleepChartItem) -> Void
    let onClearSelection: () -> Void

    private let axisWidth: CGFloat = 48
    private let labelHeight: CGFloat = 28

    private var chartItems: [SleepChartItem] {
        SleepChartItem.items(from: records, period: period, anchorDate: anchorDate)
    }

    private var domainStart: Int {
        let earliest = chartItems.map(\.startMinutes).min() ?? (22 * 60)
        return min(22 * 60, (earliest / 60) * 60)
    }

    private var domainEnd: Int {
        let latest = chartItems.map(\.endMinutes).max() ?? (32 * 60)
        return max(32 * 60, ((latest + 59) / 60) * 60)
    }

    private var axisMarks: [Int] {
        Array(stride(from: domainStart, through: domainEnd, by: 120))
    }

    var body: some View {
        GeometryReader { proxy in
            let chartWidth = max(1, proxy.size.width - axisWidth)
            let chartHeight = max(1, proxy.size.height - labelHeight)

            HStack(alignment: .top, spacing: 8) {
                ZStack(alignment: .topLeading) {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onClearSelection()
                        }

                    ForEach(axisMarks, id: \.self) { minute in
                        let y = yPosition(for: minute, height: chartHeight)

                        Rectangle()
                            .fill(Color.secondary.opacity(0.10))
                            .frame(width: chartWidth, height: 1)
                            .offset(y: y)
                    }

                    HStack(alignment: .top, spacing: barSpacing(for: chartItems.count)) {
                        ForEach(chartItems) { item in
                            SleepVerticalBar(
                                item: item,
                                isSelected: item.recordID == selectedRecordID,
                                tint: tint,
                                domainStart: domainStart,
                                domainEnd: domainEnd,
                                chartHeight: chartHeight,
                                onSelect: onSelect
                            )
                        }
                    }
                    .frame(width: chartWidth, height: chartHeight, alignment: .top)
                }
                .frame(width: chartWidth, height: chartHeight, alignment: .topLeading)

                ZStack(alignment: .topLeading) {
                    ForEach(axisMarks, id: \.self) { minute in
                        Text(Self.hourLabel(minute))
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                            .offset(y: yPosition(for: minute, height: chartHeight) - 7)
                    }
                }
                .frame(width: axisWidth, height: chartHeight, alignment: .topLeading)
            }
            .overlay(alignment: .bottomLeading) {
                HStack(alignment: .top, spacing: barSpacing(for: chartItems.count)) {
                    ForEach(chartItems) { item in
                        Text(item.label)
                            .font(.caption2.weight(.black))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.55)
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(width: chartWidth)
                .offset(y: labelHeight - 2)
            }
        }
        .padding(12)
        .background(AppTheme.fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func yPosition(for minutes: Int, height: CGFloat) -> CGFloat {
        let clamped = min(max(minutes, domainStart), domainEnd)
        let percentage = CGFloat(clamped - domainStart) / CGFloat(max(1, domainEnd - domainStart))
        return height * percentage
    }

    private func barSpacing(for count: Int) -> CGFloat {
        count > 16 ? 4 : 10
    }

    static func hourLabel(_ minutes: Int) -> String {
        let hour = ((minutes / 60) % 24 + 24) % 24
        let languageCode = UserDefaults.standard.string(forKey: AppLanguage.storageKey) ?? AppLanguage.english.rawValue
        if AppLanguage(code: languageCode) == .chinese {
            return String(format: "%02d:00", hour)
        }

        switch hour {
        case 0:
            return "12 AM"
        case 1...11:
            return "\(hour) AM"
        case 12:
            return "12 PM"
        default:
            return "\(hour - 12) PM"
        }
    }
}

struct SleepVerticalBar: View {
    let item: SleepChartItem
    let isSelected: Bool
    let tint: Color
    let domainStart: Int
    let domainEnd: Int
    let chartHeight: CGFloat
    let onSelect: (SleepChartItem) -> Void

    private var topY: CGFloat {
        yPosition(for: item.startMinutes)
    }

    private var bottomY: CGFloat {
        yPosition(for: item.endMinutes)
    }

    private var barHeight: CGFloat {
        max(8, bottomY - topY)
    }

    var body: some View {
        Button {
            guard item.durationMinutes > 0 else { return }
            onSelect(item)
        } label: {
            ZStack(alignment: .top) {
                if item.durationMinutes > 0 {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(tint.opacity(isSelected ? 1 : 0.90))
                        .frame(maxWidth: .infinity)
                        .frame(height: barHeight)
                        .overlay {
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .stroke(isSelected ? AppTheme.text.opacity(0.25) : Color.clear, lineWidth: 2)
                        }
                        .offset(y: topY)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: chartHeight, alignment: .top)
        }
        .buttonStyle(.plain)
        .disabled(item.durationMinutes == 0)
    }

    private func yPosition(for minutes: Int) -> CGFloat {
        let clamped = min(max(minutes, domainStart), domainEnd)
        let percentage = CGFloat(clamped - domainStart) / CGFloat(max(1, domainEnd - domainStart))
        return chartHeight * percentage
    }
}

struct SleepChartItem: Identifiable {
    let id: String
    let recordID: UUID?
    let date: Date
    let startMinutes: Int
    let endMinutes: Int
    let durationMinutes: Int
    let label: String

    static func items(from records: [SleepTrackerRecord], period: SleepHistoryPeriod, anchorDate: Date) -> [SleepChartItem] {
        if period == .week {
            return weeklyItems(from: records, anchorDate: anchorDate)
        }

        if period == .sixMonths {
            return monthlyItems(from: records)
        }

        return records.enumerated().map { index, record in
            SleepChartItem(
                id: record.id.uuidString,
                recordID: record.id,
                date: record.date,
                startMinutes: record.startMinutes,
                endMinutes: record.endMinutes,
                durationMinutes: record.durationMinutes,
                label: label(for: record, index: index, total: records.count, period: period)
            )
        }
    }

    private static func weeklyItems(from records: [SleepTrackerRecord], anchorDate: Date) -> [SleepChartItem] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: anchorDate)

        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset - 6, to: today) else {
                return nil
            }

            if let record = records
                .filter({ calendar.isDate($0.date, inSameDayAs: date) })
                .sorted(by: { $0.date > $1.date })
                .first {
                return SleepChartItem(
                    id: record.id.uuidString,
                    recordID: record.id,
                    date: record.date,
                    startMinutes: record.startMinutes,
                    endMinutes: record.endMinutes,
                    durationMinutes: record.durationMinutes,
                    label: localizedDateFormatString(date, format: "EEE")
                )
            }

            return SleepChartItem(
                id: "empty-\(date.timeIntervalSince1970)",
                recordID: nil,
                date: date,
                startMinutes: 22 * 60,
                endMinutes: 22 * 60,
                durationMinutes: 0,
                label: localizedDateFormatString(date, format: "EEE")
            )
        }
    }

    private static func label(for record: SleepTrackerRecord, index: Int, total: Int, period: SleepHistoryPeriod) -> String {
        switch period {
        case .day, .week:
            return localizedDateFormatString(record.date, format: "EEE")
        case .month:
            guard total <= 10 || index == total / 2 else { return "" }
            return localizedDateFormatString(record.date, format: "MMM")
        case .sixMonths:
            return localizedDateFormatString(record.date, format: "MMM")
        }
    }

    private static func monthlyItems(from records: [SleepTrackerRecord]) -> [SleepChartItem] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: records) { record in
            let components = calendar.dateComponents([.year, .month], from: record.date)
            return "\(components.year ?? 0)-\(components.month ?? 0)"
        }

        return groups.compactMap { key, values in
            guard let first = values.sorted(by: { $0.date < $1.date }).first else { return nil }
            let count = max(1, values.count)
            let start = values.reduce(0) { $0 + $1.startMinutes } / count
            let end = values.reduce(0) { $0 + $1.endMinutes } / count
            let duration = values.reduce(0) { $0 + $1.durationMinutes } / count

            return SleepChartItem(
                id: key,
                recordID: nil,
                date: first.date,
                startMinutes: start,
                endMinutes: max(end, start + 8),
                durationMinutes: duration,
                label: localizedDateFormatString(first.date, format: "MMM")
            )
        }
        .sorted { $0.date < $1.date }
    }
}

struct SleepTrackerRecord: Identifiable {
    let id: UUID
    let date: Date
    let startMinutes: Int
    let endMinutes: Int
    let durationText: String
    let durationMinutes: Int
    let qualityTitle: String
    let wakingCount: Int

    var dateLabel: String {
        localizedDateFormatString(date, format: "MMM d")
    }

    init?(entry: HealthLogEntry) {
        guard entry.type == .snapshot, entry.categoryID == "sleep" else { return nil }

        self.id = entry.id
        self.date = entry.timestamp
        self.durationText = Self.durationText(from: entry.value)
        self.qualityTitle = Self.qualityTitle(from: entry.value)
        self.wakingCount = Self.wakingCount(from: entry.value)

        let lines = entry.comments
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        let sleepMinutes = lines
            .first { $0.localizedCaseInsensitiveContains("fell asleep at") }
            .flatMap { Self.minutesFromLine($0, prefix: "Fell asleep at") } ?? (21 * 60)

        let wakeMinutesRaw = lines
            .first { $0.localizedCaseInsensitiveContains("woke up at") }
            .flatMap { Self.minutesFromLine($0, prefix: "Woke up at") } ?? (7 * 60)

        self.startMinutes = Self.timelineMinutes(sleepMinutes)
        let normalizedWakeMinutes = Self.timelineMinutes(wakeMinutesRaw)
        let wakeMinutes = normalizedWakeMinutes <= self.startMinutes
            ? normalizedWakeMinutes + 24 * 60
            : normalizedWakeMinutes
        self.endMinutes = wakeMinutes
        self.durationMinutes = max(0, wakeMinutes - self.startMinutes)
    }

    private static func timelineMinutes(_ minutes: Int) -> Int {
        minutes < 18 * 60 ? minutes + 24 * 60 : minutes
    }

    private static func durationText(from value: String) -> String {
        value
            .components(separatedBy: "·")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? "Sleep"
    }

    private static func qualityTitle(from value: String) -> String {
        let parts = value
            .components(separatedBy: "·")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return parts.dropFirst().first ?? "Sleep"
    }

    private static func wakingCount(from value: String) -> Int {
        value
            .components(separatedBy: "·")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { $0.localizedCaseInsensitiveContains("wake") }
            .flatMap { Int($0.filter(\.isNumber)) } ?? 0
    }

    static func durationText(minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours == 0 {
            return "\(remainingMinutes) min"
        }

        if remainingMinutes == 0 {
            return "\(hours) hr"
        }

        return "\(hours) hr \(remainingMinutes) min"
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
                    Text(localizedAppString("No seizure logs saved yet."))
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
        .navigationTitle(localizedAppString("Seizure History"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MedicineHistoryDetailView: View {
    let option: QuickLogOption
    let entries: [HealthLogEntry]

    private var days: [MedicineHistoryDay] {
        MedicineHistoryDay.days(from: entries)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if days.isEmpty {
                    Text(localizedAppString("No medicine checklist saved yet."))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .authPanel()
                } else {
                    ForEach(days) { day in
                        MedicineHistoryDayCard(day: day, tint: option.tint)
                    }
                }
            }
            .padding(18)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(localizedAppString("Medicine History"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct QuickLogHistoryDetailView: View {
    let option: QuickLogOption
    let entries: [HealthLogEntry]

    private var sortedEntries: [HealthLogEntry] {
        entries.sorted { $0.timestamp > $1.timestamp }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if sortedEntries.isEmpty {
                    Text(localizedAppString("No saved logs yet"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .authPanel()
                } else {
                    ForEach(sortedEntries) { entry in
                        QuickLogHistoryLogCard(entry: entry, option: option)
                    }
                }
            }
            .padding(18)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(String(format: localizedAppString("%@ History"), localizedAppString(option.title)))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MedicineHistoryDay: Identifiable {
    let id: String
    let date: Date
    let items: [MedicineHistoryItem]

    var dateTitle: String {
        localizedDateString(date, dateStyle: .full, timeStyle: .none)
    }

    var savedTimeText: String {
        localizedDateString(date, dateStyle: .none, timeStyle: .short)
    }

    static func days(from entries: [HealthLogEntry], calendar: Calendar = .current) -> [MedicineHistoryDay] {
        let sortedEntries = entries.sorted { $0.timestamp > $1.timestamp }
        var seenDateKeys = Set<String>()
        var days: [MedicineHistoryDay] = []

        for entry in sortedEntries {
            let key = MedicationCheckState.dateKey(for: entry.timestamp, calendar: calendar)
            guard !seenDateKeys.contains(key) else { continue }

            let sortedItems = MedicineHistoryItem.items(from: entry).sorted { first, second in
                if first.timeSortMinutes == second.timeSortMinutes {
                    return first.name.localizedCaseInsensitiveCompare(second.name) == .orderedAscending
                }

                return first.timeSortMinutes < second.timeSortMinutes
            }

            guard !sortedItems.isEmpty else { continue }
            seenDateKeys.insert(key)

            days.append(
                MedicineHistoryDay(
                    id: key,
                    date: entry.timestamp,
                    items: sortedItems
                )
            )
        }

        return days
    }
}

struct MedicineHistoryItem: Identifiable {
    let id: String
    let date: Date
    let timeText: String
    let timeSortMinutes: Int
    let name: String

    static func items(from entry: HealthLogEntry) -> [MedicineHistoryItem] {
        let lines = entry.comments
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let parsed = lines.compactMap { line -> MedicineHistoryItem? in
            guard let parsedLine = Self.parseChecklistLine(line) else { return nil }

            return MedicineHistoryItem(
                id: "\(entry.id.uuidString)-\(line)",
                date: entry.timestamp,
                timeText: parsedLine.timeText,
                timeSortMinutes: Self.minutes(from: parsedLine.timeText),
                name: parsedLine.name
            )
        }

        if !parsed.isEmpty {
            return parsed
        }

        return entry.value
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0 != "No medicine checked" }
            .enumerated()
            .map { index, line in
                MedicineHistoryItem(
                    id: "\(entry.id.uuidString)-fallback-\(index)",
                    date: entry.timestamp,
                    timeText: localizedDateString(entry.timestamp, dateStyle: .none, timeStyle: .short),
                    timeSortMinutes: Self.minutes(from: entry.timestamp),
                    name: Self.cleanMedicineName(line)
                )
            }
    }

    private static func parseChecklistLine(_ line: String) -> (timeText: String, name: String)? {
        let separators = [": Checked - ", ": Not checked - "]

        for separator in separators {
            guard let range = line.range(of: separator, options: [.caseInsensitive]) else { continue }

            let timeText = line[..<range.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
            let name = line[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)

            guard !timeText.isEmpty, !name.isEmpty else { return nil }
            return (timeText, cleanMedicineName(name))
        }

        guard let range = line.range(of: ": ", options: [.backwards]) else { return nil }
        let timeText = line[..<range.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
        let name = line[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)

        guard !timeText.isEmpty, !name.isEmpty else { return nil }
        return (timeText, cleanMedicineName(name))
    }

    private static func cleanMedicineName(_ text: String) -> String {
        text
            .replacingOccurrences(of: "Checked - ", with: "", options: [.caseInsensitive])
            .replacingOccurrences(of: "Not checked - ", with: "", options: [.caseInsensitive])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func minutes(from date: Date, calendar: Calendar = .current) -> Int {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    private static func minutes(from text: String) -> Int {
        let normalized = text
            .replacingOccurrences(of: "\u{202F}", with: " ")
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"

        if let parsed = formatter.date(from: normalized.uppercased()) {
            return minutes(from: parsed)
        }

        formatter.dateFormat = "HH:mm"
        if let parsed = formatter.date(from: normalized) {
            return minutes(from: parsed)
        }

        return 0
    }
}

struct MedicineHistoryDayCard: View {
    let day: MedicineHistoryDay
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "pills.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(tint)
                    .frame(width: 42, height: 42)
                    .background(tint.opacity(0.15))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(day.dateTitle)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.text)

                    Text(String(format: localizedAppString("Last saved %@"), day.savedTimeText))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            VStack(spacing: 8) {
                ForEach(day.items) { item in
                    HStack(spacing: 10) {
                        Image(systemName: "pills.fill")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(tint)
                            .frame(width: 24)

                        Text(localizedMedicineDoseText(item.name))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(AppTheme.text)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(item.timeText)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(11)
                    .background(AppTheme.fieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
    }
}

struct QuickLogHistoryLogCard: View {
    let entry: HealthLogEntry
    let option: QuickLogOption

    private var cleanedComments: [String] {
        entry.comments
            .components(separatedBy: .newlines)
            .flatMap { $0.components(separatedBy: "\n\n") }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private var scaleMax: Int {
        option.id == "mood" ? 7 : 5
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: option.icon)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(option.tint)
                    .frame(width: 42, height: 42)
                    .background(option.tint.opacity(0.15))
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

                Text("\(entry.severity)/\(scaleMax)")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(option.tint)
                    .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 8) {
                if !entry.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    SeizureHistoryDetailRow(title: primaryValueTitle, value: entry.value)
                }

                ForEach(cleanedComments, id: \.self) { comment in
                    let parts = splitComment(comment)
                    SeizureHistoryDetailRow(title: parts.title, value: parts.value)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
    }

    private func splitComment(_ comment: String) -> (title: String, value: String) {
        guard let colonIndex = comment.firstIndex(of: ":") else {
            return ("Notes", comment)
        }

        let title = String(comment[..<colonIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
        let value = String(comment[comment.index(after: colonIndex)...]).trimmingCharacters(in: .whitespacesAndNewlines)
        return (title.isEmpty ? "Notes" : title, value.isEmpty ? comment : value)
    }

    private var primaryValueTitle: String {
        switch option.id {
        case "pain":
            return "Pain Location"
        case "cyclicVomiting":
            return "Episodes"
        case "meltdown":
            return "Summary"
        case "stimming":
            return "Summary"
        default:
            return "Mood"
        }
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
            Text(LocalizedStringKey(title))
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
                Text(LocalizedStringKey(entry.title))
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
            Text(LocalizedStringKey(title))
                .font(.caption.weight(.black))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 58, alignment: .leading)

            Text(localizedAppString(message))
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

struct InsightUnavailableIndicator: View {
    var body: some View {
        HStack {
            Spacer()

            Image(systemName: "sparkles.slash")
                .font(.headline.weight(.bold))
                .foregroundStyle(.secondary)
                .frame(width: 38, height: 38)
                .background(AppTheme.panel)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                .accessibilityLabel(localizedAppString("AI insights unavailable"))

            Spacer()
        }
    }
}

struct TherapyTrackingView: View {
    let user: CarePortalUser

    @AppStorage private var milestoneData: Data
    @State private var activeCategory: TherapyCategory?

    init(user: CarePortalUser) {
        self.user = user
        self._milestoneData = AppStorage(wrappedValue: Data(), "therapy.\(user.id).milestoneData")
    }

    private var milestones: [TherapyMilestone] {
        guard !milestoneData.isEmpty else { return [] }
        return (try? JSONDecoder().decode([TherapyMilestone].self, from: milestoneData)) ?? []
    }

    private var recentMilestones: [TherapyMilestone] {
        milestones.sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    PageHeader(
                        icon: "figure.mind.and.body",
                        title: "Therapy Tracking",
                        subtitle: "Log milestones and therapy wins to see your child's progress over time."
                    )

                    Button {
                        activeCategory = .therapySession
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: TherapyCategory.therapySession.icon)
                                .font(.headline.weight(.bold))
                                .foregroundStyle(TherapyCategory.therapySession.tint)
                                .frame(width: 40, height: 40)
                                .background(TherapyCategory.therapySession.tint.opacity(0.14))
                                .clipShape(Circle())

                            Text(localizedAppString("Therapy Session"))
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.text)

                            Spacer()

                            Image(systemName: "plus")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.accent)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.panel)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(TherapyCategory.therapySession.tint.opacity(0.18), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(TherapyCategory.all) { category in
                            TherapyCategoryCard(
                                category: category,
                                count: milestones.filter { $0.categoryID == category.id }.count
                            ) {
                                activeCategory = category
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(localizedAppString("Recent Milestones"))
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.text)

                            Spacer()

                            NavigationLink {
                                TherapyMilestoneHistoryView(milestones: milestones)
                            } label: {
                                Label(localizedAppString("History"), systemImage: "clock.arrow.circlepath")
                                    .font(.caption.weight(.black))
                                    .foregroundStyle(AppTheme.accent)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(AppTheme.accent.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }

                        if recentMilestones.isEmpty {
                            Text(localizedAppString("No milestones logged yet."))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background(AppTheme.panel)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        } else {
                            ForEach(recentMilestones.prefix(5)) { milestone in
                                TherapyMilestoneRow(milestone: milestone)
                            }
                        }
                    }
                    .authPanel()
                }
                .padding(20)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(localizedAppString("Therapy"))
            .sheet(item: $activeCategory) { category in
                TherapyMilestoneSheet(category: category) { milestone in
                    saveMilestone(milestone)
                }
            }
        }
    }

    private func saveMilestone(_ milestone: TherapyMilestone) {
        var updatedMilestones = milestones
        updatedMilestones.append(milestone)
        updatedMilestones.sort { $0.date < $1.date }

        if let data = try? JSONEncoder().encode(updatedMilestones) {
            milestoneData = data
        }
    }
}

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

struct TherapyMilestone: Identifiable, Codable {
    let id: UUID
    let categoryID: String
    let categoryTitle: String
    let date: Date
    let milestone: String
    let supportLevel: String
    let notes: String

    init(
        id: UUID = UUID(),
        categoryID: String,
        categoryTitle: String,
        date: Date,
        milestone: String,
        supportLevel: String,
        notes: String
    ) {
        self.id = id
        self.categoryID = categoryID
        self.categoryTitle = categoryTitle
        self.date = date
        self.milestone = milestone
        self.supportLevel = supportLevel
        self.notes = notes
    }
}

struct TherapyCategoryCard: View {
    let category: TherapyCategory
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: category.icon)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(category.tint)
                        .clipShape(Circle())

                    Spacer()

                    Text("\(count)")
                        .font(.caption.weight(.black))
                        .foregroundStyle(category.tint)
                        .frame(width: 30, height: 30)
                        .background(category.tint.opacity(0.14))
                        .clipShape(Circle())
                }

                Text(LocalizedStringKey(category.title))
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(LocalizedStringKey(category.examples))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 156, alignment: .topLeading)
            .background(category.tint.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(category.tint.opacity(0.2), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

struct TherapyMilestoneRow: View {
    let milestone: TherapyMilestone

    private var category: TherapyCategory? {
        TherapyCategory.category(id: milestone.categoryID)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: category?.icon ?? "star.fill")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(category?.tint ?? AppTheme.accent)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    Text(LocalizedStringKey(milestone.categoryTitle))
                        .font(.caption.weight(.black))
                        .foregroundStyle(category?.tint ?? AppTheme.accent)

                    Spacer()

                    Text(milestone.date, style: .date)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Text(milestone.milestone)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.text)
                    .fixedSize(horizontal: false, vertical: true)

                Text(LocalizedStringKey(milestone.supportLevel))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                if !milestone.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(milestone.notes)
                        .font(.caption)
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

struct TherapyMilestoneHistoryView: View {
    let milestones: [TherapyMilestone]

    @State private var selectedCategoryIDs: Set<String> = []
    @State private var startDate = Calendar.current.date(byAdding: .day, value: -7, to: Calendar.current.startOfDay(for: Date())) ?? Date()
    @State private var endDate = Date()

    private var sortedMilestones: [TherapyMilestone] {
        milestones.sorted { $0.date > $1.date }
    }

    private var filteredMilestones: [TherapyMilestone] {
        sortedMilestones.filter { milestone in
            let matchesCategory = selectedCategoryIDs.isEmpty || selectedCategoryIDs.contains(milestone.categoryID)
            let dateRange = normalizedDateRange
            return matchesCategory && milestone.date >= dateRange.start && milestone.date <= dateRange.end
        }
    }

    private var normalizedDateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let earlier = min(startDate, endDate)
        let later = max(startDate, endDate)
        let start = calendar.startOfDay(for: earlier)
        let end = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: calendar.startOfDay(for: later)) ?? later
        return (start, end)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(localizedAppString("Therapy Type"))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.text)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            TherapyFilterChip(
                                title: "All",
                                isSelected: selectedCategoryIDs.isEmpty,
                                tint: AppTheme.accent
                            ) {
                                selectedCategoryIDs.removeAll()
                            }

                            ForEach(TherapyCategory.all) { category in
                                TherapyFilterChip(
                                    title: category.title,
                                    isSelected: selectedCategoryIDs.contains(category.id),
                                    tint: category.tint
                                ) {
                                    toggleCategory(category.id)
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .authPanel()

                VStack(alignment: .leading, spacing: 10) {
                    Text(localizedAppString("Time Frame"))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.text)

                    VStack(spacing: 10) {
                        DatePicker(
                            localizedAppString("Start Date"),
                            selection: $startDate,
                            displayedComponents: .date
                        )
                        .font(.subheadline.weight(.semibold))

                        DatePicker(
                            localizedAppString("End Date"),
                            selection: $endDate,
                            displayedComponents: .date
                        )
                        .font(.subheadline.weight(.semibold))
                    }
                    .padding(12)
                    .background(AppTheme.fieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .authPanel()

                VStack(alignment: .leading, spacing: 12) {
                    Text(localizedAppString("Milestones"))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.text)

                    if filteredMilestones.isEmpty {
                        Text(localizedAppString("No milestones found."))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(AppTheme.panel)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    } else {
                        ForEach(filteredMilestones) { milestone in
                            TherapyMilestoneRow(milestone: milestone)
                        }
                    }
                }
                .authPanel()
            }
            .padding(20)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(localizedAppString("History"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func toggleCategory(_ id: String) {
        if selectedCategoryIDs.contains(id) {
            selectedCategoryIDs.remove(id)
        } else {
            selectedCategoryIDs.insert(id)
        }
    }
}

struct TherapyFilterChip: View {
    let title: String
    let isSelected: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(localizedAppString(title))
                .font(.caption.weight(.black))
                .foregroundStyle(isSelected ? .white : tint)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(isSelected ? tint : tint.opacity(0.12))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct TherapyMilestoneSheet: View {
    @Environment(\.dismiss) private var dismiss

    let category: TherapyCategory
    let onSave: (TherapyMilestone) -> Void

    @State private var date = Date()
    @State private var milestone = ""
    @State private var supportLevel = "With full support"
    @State private var notes = ""

    private let supportLevels = [
        "With full support",
        "With some support",
        "With a prompt",
        "Mostly independent",
        "Independent"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 12) {
                            Image(systemName: category.icon)
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(category.tint)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 3) {
                                Text(LocalizedStringKey(category.title))
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(AppTheme.text)

                                Text(localizedAppString("Log a new milestone"))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }

                        DatePicker(localizedAppString("Date"), selection: $date, displayedComponents: .date)
                            .font(.subheadline.weight(.semibold))
                            .padding(12)
                            .background(AppTheme.fieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        ProfileTextField(
                            title: "Milestone",
                            text: $milestone,
                            placeholder: "Example: Used two-word request",
                            axis: .vertical
                        )

                        VStack(alignment: .leading, spacing: 8) {
                            Text(localizedAppString("Support level"))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.text)

                            Picker(localizedAppString("Support level"), selection: $supportLevel) {
                                ForEach(supportLevels, id: \.self) { level in
                                    Text(LocalizedStringKey(level)).tag(level)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(AppTheme.fieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        ProfileTextField(
                            title: "Notes",
                            text: $notes,
                            placeholder: "What helped, where it happened, or what to practice next",
                            axis: .vertical
                        )
                    }
                    .padding(20)
                }

                StickyBottomSaveButton(
                    title: "Save",
                    tint: category.tint,
                    isDisabled: milestone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ) {
                    save()
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(localizedAppString("Milestone"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(localizedAppString("Cancel")) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func save() {
        let trimmedMilestone = milestone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMilestone.isEmpty else { return }

        onSave(
            TherapyMilestone(
                categoryID: category.id,
                categoryTitle: category.title,
                date: date,
                milestone: trimmedMilestone,
                supportLevel: supportLevel,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        )
        dismiss()
    }
}

struct NutrientView: View {
    let user: CarePortalUser

    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.english.rawValue
    @AppStorage private var mealPhotoData: Data
    @AppStorage private var mealEstimateData: Data
    @AppStorage private var savedMealHistoryData: Data
    @AppStorage private var dailyUsageData: Data
    @AppStorage private var dailyEstimateLimit: Int
    @AppStorage private var nutritionGoalsData: Data
    @State private var selectedMealPhoto: PhotosPickerItem?
    @State private var isMealPhotoSourcePresented = false
    @State private var isCameraPickerPresented = false
    @State private var isEstimating = false
    @State private var estimateError = ""
    @State private var saveMessage = ""
    @State private var hasSavedCurrentMeal = false
    @State private var isEstimateEditorPresented = false
    @State private var isManualMealEntryPresented = false
    @State private var activeMealPDF: MealPDFShareItem?
    @State private var nutritionGoals = NutritionGoals()

    init(user: CarePortalUser) {
        self.user = user
        self._mealPhotoData = AppStorage(wrappedValue: Data(), "nutrient.\(user.id).mealPhotoData")
        self._mealEstimateData = AppStorage(wrappedValue: Data(), "nutrient.\(user.id).mealEstimateData")
        self._savedMealHistoryData = AppStorage(wrappedValue: Data(), "nutrient.\(user.id).savedMealHistoryData")
        self._dailyUsageData = AppStorage(wrappedValue: Data(), "nutrient.\(user.id).dailyUsageData")
        self._dailyEstimateLimit = AppStorage(wrappedValue: 3, "nutrient.\(user.id).dailyEstimateLimit")
        self._nutritionGoalsData = AppStorage(wrappedValue: Data(), "nutrient.\(user.id).nutritionGoalsData")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .top, spacing: 12) {
                        PageHeader(
                            icon: "leaf",
                            title: "Nutrient",
                            subtitle: "Estimate meals, hydration, safe foods, and feeding patterns."
                        )

                        NavigationLink {
                            MealHistoryView(savedMeals: savedMealHistory)
                        } label: {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.accent)
                                .frame(width: 44, height: 44)
                                .background(AppTheme.accent.opacity(0.12))
                                .clipShape(Circle())
                        }
                        .accessibilityLabel(localizedAppString("Meal history"))
                        .padding(.top, 2)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        NutrientDailyLimitSummary(
                            estimateCount: dailyUsage.estimateCount,
                            limit: dailyEstimateLimit
                        )

                        NavigationLink {
                            NutritionGoalsPage(goals: $nutritionGoals) {
                                saveNutritionGoals()
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Text(localizedAppString(nutritionGoals.isEmpty ? "Set Nutrition Goals" : "View Nutrition Goals"))
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(AppTheme.accent)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(AppTheme.text.opacity(0.75))
                            }
                            .padding(16)
                            .background(AppTheme.panel)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)

                        Button {
                            openMealPhotoSource()
                        } label: {
                            MealPhotoUploadPanel(imageData: mealPhotoData)
                                .opacity(canUploadMealPhoto ? 1 : 0.55)
                        }
                        .buttonStyle(.plain)

                        Button {
                            isManualMealEntryPresented = true
                        } label: {
                            Label(localizedAppString("Add Meal Manually"), systemImage: "square.and.pencil")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.accent)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.accent.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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

                                Text(localizedAppString(isEstimating ? "Estimating..." : "Estimate Nutrients"))
                                    .font(.headline.weight(.bold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(mealPhotoData.isEmpty || !canEstimateMeal ? Color.gray.opacity(0.45) : AppTheme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .disabled(mealPhotoData.isEmpty || isEstimating)

                        if !estimateError.isEmpty {
                            Text(estimateError)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.red)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if !saveMessage.isEmpty {
                            Text(saveMessage)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(AppTheme.accent)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if let estimate = mealEstimate {
                            Button {
                                saveCurrentMeal(estimate)
                            } label: {
                                Label(localizedAppString(hasSavedCurrentMeal ? "Saved" : "Save Meal"), systemImage: hasSavedCurrentMeal ? "checkmark.circle.fill" : "tray.and.arrow.down.fill")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(hasSavedCurrentMeal ? Color.gray.opacity(0.55) : AppTheme.accent)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .disabled(mealPhotoData.isEmpty || hasSavedCurrentMeal)

                            Button {
                                exportCurrentMealPDF(estimate)
                            } label: {
                                Label(localizedAppString("Export as PDF"), systemImage: "doc.richtext.fill")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(AppTheme.accent)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(AppTheme.accent.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .disabled(mealPhotoData.isEmpty)

                            MealNutritionEstimateView(estimate: estimate)
                                .onTapGesture {
                                    isEstimateEditorPresented = true
                                }
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                HealthMetricRow(icon: "fork.knife", title: "Meals", value: localizedAppString("0 analyzed"))
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
            .navigationTitle(localizedAppString("Nutrient"))
            .onAppear {
                resetCurrentMealForNextImage()
                loadStoredNutritionGoals()
                syncSavedMealHistoryIfNeeded()
                syncNutrientDailyUsage(dailyUsage)
            }
            .task {
                await refreshNutrientSettings()
            }
            .task(id: selectedMealPhoto) {
                await loadSelectedMealPhoto()
            }
            .sheet(isPresented: $isMealPhotoSourcePresented) {
                MealPhotoSourceSheet(
                    selectedMealPhoto: $selectedMealPhoto,
                    cameraAvailable: UIImagePickerController.isSourceTypeAvailable(.camera),
                    takePhoto: openMealCamera,
                    cameraUnavailable: {
                        saveMessage = localizedAppString("Camera unavailable on this device.")
                    }
                )
                .presentationDetents([.height(240)])
                .presentationDragIndicator(.visible)
            }
            .fullScreenCover(isPresented: $isCameraPickerPresented) {
                CameraMealPhotoPicker { data in
                    applyMealPhotoData(data)
                }
                .ignoresSafeArea()
            }
            .sheet(item: $activeMealPDF) { item in
                PDFShareSheet(url: item.url)
            }
            .sheet(isPresented: $isEstimateEditorPresented) {
                if let estimate = mealEstimate {
                    MealEstimateEditorSheet(
                        title: "Edit Nutrient Estimate",
                        estimate: estimate,
                        requiresPhoto: false
                    ) { updatedEstimate in
                        updateCurrentEstimate(updatedEstimate)
                    }
                }
            }
            .sheet(isPresented: $isManualMealEntryPresented) {
                ManualMealEntrySheet { imageData, estimate in
                    saveManualMeal(imageData: imageData, estimate: estimate)
                }
            }
        }
    }

    private func resetCurrentMealForNextImage() {
        mealPhotoData = Data()
        mealEstimateData = Data()
        selectedMealPhoto = nil
        estimateError = ""
        saveMessage = ""
        hasSavedCurrentMeal = false
        isEstimating = false
    }

    private func syncSavedMealHistoryIfNeeded() {
        let meals = savedMealHistory
        guard !meals.isEmpty else { return }
        syncSavedMeals(meals, showFailure: true)
    }

    private var mealEstimate: MealNutritionEstimate? {
        guard !mealEstimateData.isEmpty else { return nil }
        return try? JSONDecoder().decode(MealNutritionEstimate.self, from: mealEstimateData)
    }

    private var savedMealHistory: [SavedMealEstimate] {
        guard !savedMealHistoryData.isEmpty,
              let savedMeals = try? JSONDecoder().decode([SavedMealEstimate].self, from: savedMealHistoryData) else {
            return []
        }

        return savedMeals.sorted { $0.savedAt > $1.savedAt }
    }

    private var dailyUsage: NutrientDailyUsage {
        guard !dailyUsageData.isEmpty,
              let usage = try? JSONDecoder().decode(NutrientDailyUsage.self, from: dailyUsageData),
              usage.dateKey == MedicationCheckState.todayKey else {
            return NutrientDailyUsage.today()
        }

        return usage
    }

    private var canUploadMealPhoto: Bool {
        canEstimateMeal
    }

    private var canEstimateMeal: Bool {
        dailyUsage.estimateCount < dailyEstimateLimit
    }

    private func openMealPhotoSource() {
        guard canUploadMealPhoto else {
            saveMessage = String(
                format: localizedAppString("Daily nutrient estimate limit reached with limit %@."),
                "\(dailyEstimateLimit)"
            )
            return
        }

        isMealPhotoSourcePresented = true
    }

    private func loadSelectedMealPhoto() async {
        guard let selectedMealPhoto else { return }

        do {
            if let data = try await selectedMealPhoto.loadTransferable(type: Data.self) {
                await MainActor.run {
                    applyMealPhotoData(data)
                }
            }
        } catch {
            // Photo selection is user-driven; keeping the existing photo avoids data loss.
        }
    }

    private func openMealCamera() {
        guard canUploadMealPhoto else {
            saveMessage = String(
                format: localizedAppString("Daily nutrient estimate limit reached with limit %@."),
                "\(dailyEstimateLimit)"
            )
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isCameraPickerPresented = true
        }
    }

    private func applyMealPhotoData(_ data: Data) {
        guard canUploadMealPhoto else {
            selectedMealPhoto = nil
            saveMessage = String(
                format: localizedAppString("Daily nutrient estimate limit reached with limit %@."),
                "\(dailyEstimateLimit)"
            )
            return
        }

        mealPhotoData = data
        mealEstimateData = Data()
        selectedMealPhoto = nil
        estimateError = ""
        saveMessage = ""
        hasSavedCurrentMeal = false
    }

    private func estimateMeal() {
        guard !mealPhotoData.isEmpty else { return }
        guard canEstimateMeal else {
            estimateError = String(
                format: localizedAppString("Daily nutrient estimate limit reached with limit %@."),
                "\(dailyEstimateLimit)"
            )
            return
        }

        isEstimating = true
        estimateError = ""
        saveMessage = ""
        hasSavedCurrentMeal = false
        incrementDailyUsage(estimate: 1)

        Task {
            do {
                let estimate = try await NutritionAPI().analyzeMeal(
                    imageData: mealImageDataURL(),
                    language: AppLanguage(code: languageCode).apiName
                )
                await MainActor.run {
                    if let data = try? JSONEncoder().encode(estimate) {
                        mealEstimateData = data
                    }
                    applyMealEstimateToNutritionGoals(estimate)
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

    private func incrementDailyUsage(upload: Int = 0, estimate: Int = 0) {
        var usage = dailyUsage
        usage.uploadCount += upload
        usage.estimateCount += estimate

        if let data = try? JSONEncoder().encode(usage) {
            dailyUsageData = data
        }

        syncNutrientDailyUsage(usage)
    }

    private func refreshNutrientSettings() async {
        do {
            let settings = try await AuthAPI().appSettings(userId: user.id)
            await MainActor.run {
                dailyEstimateLimit = max(0, settings.nutrientDailyLimit)
            }
        } catch {
            // The local limit remains usable if the backend is offline.
        }
    }

    private func syncNutrientDailyUsage(_ usage: NutrientDailyUsage) {
        Task {
            do {
                try await AuthAPI().syncAppData(
                    userId: user.id,
                    childProfile: nil,
                    healthLogs: nil,
                    savedMeals: nil,
                    nutrientDailyUsage: usage
                )
            } catch {
                print("Nutrient usage sync failed for user \(user.id): \(error.localizedDescription)")
            }
        }
    }

    private func saveCurrentMeal(_ estimate: MealNutritionEstimate) {
        guard !mealPhotoData.isEmpty else { return }
        guard !hasSavedCurrentMeal else { return }

        var savedMeals = savedMealHistory
        let savedImageData = savedMealImageData()
        savedMeals.insert(
            SavedMealEstimate(
                savedAt: Date(),
                imageData: savedImageData,
                estimate: estimate
            ),
            at: 0
        )

        if let data = try? JSONEncoder().encode(savedMeals) {
            savedMealHistoryData = data
            saveMessage = localizedAppString("Meal saved to history.")
            hasSavedCurrentMeal = true
            syncSavedMeals(savedMeals, showFailure: true)
            mealPhotoData = Data()
            mealEstimateData = Data()
            selectedMealPhoto = nil
        } else {
            saveMessage = localizedAppString("Unable to save this meal.")
        }
    }

    private func updateCurrentEstimate(_ estimate: MealNutritionEstimate) {
        if let data = try? JSONEncoder().encode(estimate) {
            mealEstimateData = data
            hasSavedCurrentMeal = false
            saveMessage = localizedAppString("Estimate updated. Save meal to keep the corrected information in history.")
        } else {
            saveMessage = localizedAppString("Unable to update this estimate.")
        }
    }

    private func saveManualMeal(imageData: Data, estimate: MealNutritionEstimate) {
        guard !imageData.isEmpty else {
            saveMessage = localizedAppString("Add a meal photo before saving.")
            return
        }

        var savedMeals = savedMealHistory
        let compressedImageData = savedMealImageData(from: imageData)
        savedMeals.insert(
            SavedMealEstimate(
                savedAt: Date(),
                imageData: compressedImageData,
                estimate: estimate
            ),
            at: 0
        )

        if let data = try? JSONEncoder().encode(savedMeals) {
            savedMealHistoryData = data
            saveMessage = localizedAppString("Manual meal saved to history.")
            applyMealEstimateToNutritionGoals(estimate)
            syncSavedMeals(savedMeals, showFailure: true)
        } else {
            saveMessage = localizedAppString("Unable to save this meal.")
        }
    }

    private func exportCurrentMealPDF(_ estimate: MealNutritionEstimate) {
        guard !mealPhotoData.isEmpty,
              let url = MealPDFExporter.export(imageData: mealPhotoData, estimate: estimate, savedAt: Date()) else {
            saveMessage = localizedAppString("Unable to create PDF.")
            return
        }

        activeMealPDF = MealPDFShareItem(url: url)
    }

    private func syncSavedMeals(_ savedMeals: [SavedMealEstimate], showFailure: Bool = false) {
        guard !savedMeals.isEmpty else { return }

        let backendMeals = savedMeals.map { meal in
            SavedMealEstimate(
                id: meal.id,
                savedAt: meal.savedAt,
                imageData: Data(),
                estimate: meal.estimate
            )
        }

        Task {
            do {
                try await AuthAPI().syncAppData(
                    userId: user.id,
                    childProfile: nil,
                    healthLogs: nil,
                    savedMeals: backendMeals
                )
                print("Saved nutrient meals synced for user \(user.id). Meals: \(backendMeals.count)")
            } catch {
                if showFailure {
                    await MainActor.run {
                        saveMessage = localizedAppString("Meal saved on this phone, but backend sync failed. Make sure the configured server is reachable.")
                    }
                }
                print("Saved nutrient meals sync failed for user \(user.id): \(error.localizedDescription)")
            }
        }
    }

    private var storedNutritionGoals: NutritionGoals {
        guard !nutritionGoalsData.isEmpty,
              let savedGoals = try? JSONDecoder().decode(NutritionGoals.self, from: nutritionGoalsData) else {
            return NutritionGoals()
        }

        return savedGoals
    }

    private func loadStoredNutritionGoals() {
        nutritionGoals = storedNutritionGoals
        let previousDateKey = nutritionGoals.consumedDateKey
        nutritionGoals.resetDailyProgressIfNeeded()
        if previousDateKey != nutritionGoals.consumedDateKey {
            saveNutritionGoals(showMessage: false)
        }
    }

    private func saveNutritionGoals(showMessage: Bool = true) {
        nutritionGoals.lastUpdated = Date()
        if let data = try? JSONEncoder().encode(nutritionGoals) {
            nutritionGoalsData = data
            if showMessage {
                saveMessage = localizedAppString("Nutrition goals saved")
            }
        }
    }

    private func applyMealEstimateToNutritionGoals(_ estimate: MealNutritionEstimate) {
        nutritionGoals.applyMealEstimate(estimate)
        if nutritionGoals.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            nutritionGoals.notes = localizedAppString("Auto-filled from latest AI meal estimate.")
        }
        saveNutritionGoals(showMessage: false)
    }

    private func savedMealImageData() -> Data {
        savedMealImageData(from: mealPhotoData)
    }

    private func savedMealImageData(from imageData: Data) -> Data {
        if let image = UIImage(data: imageData),
           let jpegData = image.resizedForMealAnalysis(maxDimension: 900).jpegData(compressionQuality: 0.72) {
            return jpegData
        }

        return imageData
    }

    private func mealImageDataURL() -> String {
        if let image = UIImage(data: mealPhotoData),
           let jpegData = image.resizedForMealAnalysis(maxDimension: 1200).jpegData(compressionQuality: 0.74) {
            return "data:image/jpeg;base64,\(jpegData.base64EncodedString())"
        }

        return "data:image/jpeg;base64,\(mealPhotoData.base64EncodedString())"
    }
}

struct NutrientDailyUsage: Codable {
    var dateKey: String
    var uploadCount: Int
    var estimateCount: Int

    static func today() -> NutrientDailyUsage {
        NutrientDailyUsage(
            dateKey: MedicationCheckState.todayKey,
            uploadCount: 0,
            estimateCount: 0
        )
    }
}

struct NutrientDailyLimitSummary: View {
    let estimateCount: Int
    let limit: Int

    private var estimatesLeft: Int {
        max(0, limit - estimateCount)
    }

    private var limitColor: Color {
        if estimatesLeft == 0 {
            return .red
        }

        if estimatesLeft == limit {
            return AppTheme.accent
        }

        return .orange
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.caption.weight(.bold))

            Text(localizedAppString("Estimates Left Today"))
                .font(.caption.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text("\(estimatesLeft)/\(limit)")
                .font(.caption.weight(.black))
        }
        .foregroundStyle(limitColor)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(limitColor.opacity(0.12))
        .clipShape(Capsule())
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
        summary = try container.decodeIfPresent(String.self, forKey: .summary) ?? localizedAppString("This is a photo-based meal estimate.")
        recommendations = try container.decodeIfPresent([String].self, forKey: .recommendations) ?? []
        notes = try container.decodeIfPresent([String].self, forKey: .notes) ?? []
    }
}

struct SavedMealEstimate: Codable, Identifiable {
    let id: UUID
    let savedAt: Date
    let imageData: Data
    let estimate: MealNutritionEstimate

    init(id: UUID = UUID(), savedAt: Date, imageData: Data, estimate: MealNutritionEstimate) {
        self.id = id
        self.savedAt = savedAt
        self.imageData = imageData
        self.estimate = estimate
    }
}

struct MealPDFShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

struct PDFShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
    }
}

enum MealPDFExporter {
    static func export(imageData: Data, estimate: MealNutritionEstimate, savedAt: Date) -> URL? {
        let fileName = "Meal-Nutrition-\(Int(savedAt.timeIntervalSince1970)).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        do {
            try renderer.writePDF(to: url) { context in
                context.beginPage()

                var y: CGFloat = 36
                y += drawText(
                    localizedAppString("Meal Nutrition Estimate"),
                    in: CGRect(x: 36, y: y, width: 540, height: 40),
                    font: .boldSystemFont(ofSize: 24),
                    color: UIColor(red: 0.12, green: 0.17, blue: 0.16, alpha: 1)
                ) + 8

                y += drawText(
                    localizedDateString(savedAt, dateStyle: .full, timeStyle: .short),
                    in: CGRect(x: 36, y: y, width: 540, height: 28),
                    font: .systemFont(ofSize: 12, weight: .semibold),
                    color: .secondaryLabel
                ) + 16

                if let image = UIImage(data: imageData) {
                    let imageRect = aspectFitRect(for: image.size, in: CGRect(x: 36, y: y, width: 260, height: 210))
                    image.draw(in: imageRect)
                }

                let metrics = [
                    "\(localizedAppString("Calories")): \(estimate.calories) \(localizedAppString("kcal"))",
                    "\(localizedAppString("Protein")): \(estimate.protein) g",
                    "\(localizedAppString("Carbs")): \(estimate.carbs) g",
                    "\(localizedAppString("Fat")): \(estimate.fat) g",
                    "\(localizedAppString("Fiber")): \(estimate.fiber) g",
                    "\(localizedAppString("Sugar")): \(estimate.sugar) g",
                    "\(localizedAppString("Confidence")): \(localizedAppString(estimate.confidence))"
                ].joined(separator: "\n")

                _ = drawText(
                    metrics,
                    in: CGRect(x: 320, y: y, width: 256, height: 210),
                    font: .systemFont(ofSize: 14, weight: .semibold),
                    color: .label
                )
                y += 230

                y += drawSection(title: localizedAppString("Summary"), body: localizedSavedAIText(estimate.summary), y: y, pageWidth: pageRect.width) + 12
                y += drawSection(title: localizedAppString("Recommendations"), body: bulletList(estimate.recommendations.map(localizedSavedAIText)), y: y, pageWidth: pageRect.width) + 12
                _ = drawSection(title: localizedAppString("Notes"), body: bulletList(estimate.notes.map(localizedSavedAIText)), y: y, pageWidth: pageRect.width)
            }

            return url
        } catch {
            return nil
        }
    }

    private static func drawSection(title: String, body: String, y: CGFloat, pageWidth: CGFloat) -> CGFloat {
        var currentY = y
        currentY += drawText(
            title,
            in: CGRect(x: 36, y: currentY, width: pageWidth - 72, height: 24),
            font: .boldSystemFont(ofSize: 15),
            color: UIColor(red: 0.12, green: 0.17, blue: 0.16, alpha: 1)
        ) + 6

        currentY += drawText(
            body.isEmpty ? localizedAppString("No information available.") : body,
            in: CGRect(x: 36, y: currentY, width: pageWidth - 72, height: 140),
            font: .systemFont(ofSize: 12, weight: .medium),
            color: .label
        )

        return currentY - y
    }

    private static func drawText(_ text: String, in rect: CGRect, font: UIFont, color: UIColor) -> CGFloat {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 4
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        let neededRect = attributedText.boundingRect(
            with: CGSize(width: rect.width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        attributedText.draw(in: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: min(rect.height, ceil(neededRect.height))))
        return min(rect.height, ceil(neededRect.height))
    }

    private static func bulletList(_ items: [String]) -> String {
        guard !items.isEmpty else { return "" }
        return items.map { "- \($0)" }.joined(separator: "\n")
    }

    private static func aspectFitRect(for imageSize: CGSize, in boundingRect: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return boundingRect }
        let scale = min(boundingRect.width / imageSize.width, boundingRect.height / imageSize.height)
        let width = imageSize.width * scale
        let height = imageSize.height * scale
        return CGRect(
            x: boundingRect.midX - width / 2,
            y: boundingRect.midY - height / 2,
            width: width,
            height: height
        )
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

struct MealPhotoSourceSheet: View {
    @Binding var selectedMealPhoto: PhotosPickerItem?
    let cameraAvailable: Bool
    let takePhoto: () -> Void
    let cameraUnavailable: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 12) {
            Capsule()
                .fill(Color.secondary.opacity(0.25))
                .frame(width: 42, height: 5)
                .padding(.top, 4)

            Text(localizedAppString("Meal Photo"))
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.text)

            Button {
                dismiss()
                if cameraAvailable {
                    takePhoto()
                } else {
                    cameraUnavailable()
                }
            } label: {
                Label(localizedAppString("Take Photo"), systemImage: "camera.fill")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(cameraAvailable ? AppTheme.accent : Color.gray.opacity(0.55))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            PhotosPicker(selection: $selectedMealPhoto, matching: .images) {
                Label(localizedAppString("Choose from Library"), systemImage: "photo.on.rectangle")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.accent.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(20)
        .background(AppTheme.background.ignoresSafeArea())
        .onChange(of: selectedMealPhoto) { _, newValue in
            if newValue != nil {
                dismiss()
            }
        }
    }
}

struct CameraMealPhotoPicker: UIViewControllerRepresentable {
    let onImageData: (Data) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraMealPhotoPicker

        init(parent: CameraMealPhotoPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage,
               let data = image.resizedForMealAnalysis(maxDimension: 1600).jpegData(compressionQuality: 0.78) {
                parent.onImageData(data)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct MealEstimateEditorSheet: View {
    let title: String
    let estimate: MealNutritionEstimate
    var requiresPhoto = false
    var imageData: Data = Data()
    let onSave: (MealNutritionEstimate) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var calories: String
    @State private var protein: String
    @State private var carbs: String
    @State private var fat: String
    @State private var fiber: String
    @State private var sugar: String
    @State private var summary: String
    @State private var recommendations: String
    @State private var notes: String

    init(
        title: String,
        estimate: MealNutritionEstimate,
        requiresPhoto: Bool = false,
        imageData: Data = Data(),
        onSave: @escaping (MealNutritionEstimate) -> Void
    ) {
        self.title = title
        self.estimate = estimate
        self.requiresPhoto = requiresPhoto
        self.imageData = imageData
        self.onSave = onSave
        self._calories = State(initialValue: "\(estimate.calories)")
        self._protein = State(initialValue: "\(estimate.protein)")
        self._carbs = State(initialValue: "\(estimate.carbs)")
        self._fat = State(initialValue: "\(estimate.fat)")
        self._fiber = State(initialValue: "\(estimate.fiber)")
        self._sugar = State(initialValue: "\(estimate.sugar)")
        self._summary = State(initialValue: estimate.summary)
        self._recommendations = State(initialValue: estimate.recommendations.joined(separator: "\n"))
        self._notes = State(initialValue: estimate.notes.joined(separator: "\n"))
    }

    private var canSave: Bool {
        (!requiresPhoto || !imageData.isEmpty)
            && intValue(calories) > 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let image = UIImage(data: imageData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text(localizedAppString("Calories"))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.text)

                        NutrientNumberInput(title: "Calories", unit: "kcal", text: $calories)
                    }
                    .nutritionEditCard()

                    VStack(alignment: .leading, spacing: 12) {
                        Text(localizedAppString("Macronutrients"))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.text)

                        NutrientNumberInput(title: "Protein", unit: "g", text: $protein)
                        NutrientNumberInput(title: "Carbs", unit: "g", text: $carbs)
                        NutrientNumberInput(title: "Fat", unit: "g", text: $fat)
                    }
                    .nutritionEditCard()

                    VStack(alignment: .leading, spacing: 12) {
                        Text(localizedAppString("More Nutrition Details"))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.text)

                        NutrientNumberInput(title: "Fiber", unit: "g", text: $fiber)
                        NutrientNumberInput(title: "Sugar", unit: "g", text: $sugar)
                    }
                    .nutritionEditCard()

                    VStack(alignment: .leading, spacing: 12) {
                        Text(localizedAppString("Summary"))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.text)

                        TextField(localizedAppString("Meal summary"), text: $summary, axis: .vertical)
                            .lineLimit(3...5)
                            .nutritionTextFieldStyle()

                        Text(localizedAppString("Recommendations"))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(AppTheme.text)

                        TextField(localizedAppString("One recommendation per line"), text: $recommendations, axis: .vertical)
                            .lineLimit(3...6)
                            .nutritionTextFieldStyle()

                        Text(localizedAppString("Notes"))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(AppTheme.text)

                        TextField(localizedAppString("One note per line"), text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                            .nutritionTextFieldStyle()
                    }
                    .nutritionEditCard()
                }
                .padding(20)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(localizedAppString(title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(localizedAppString("Cancel")) {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.accent)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(localizedAppString("Save")) {
                        onSave(makeEstimate())
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(canSave ? AppTheme.accent : .secondary)
                    .disabled(!canSave)
                }
            }
        }
    }

    private func makeEstimate() -> MealNutritionEstimate {
        MealNutritionEstimate(
            calories: intValue(calories),
            protein: intValue(protein),
            carbs: intValue(carbs),
            fat: intValue(fat),
            fiber: intValue(fiber),
            sugar: intValue(sugar),
            confidence: estimate.confidence,
            summary: summary.trimmingCharacters(in: .whitespacesAndNewlines),
            recommendations: lineList(from: recommendations),
            notes: lineList(from: notes)
        )
    }

    private func intValue(_ text: String) -> Int {
        Int(text.filter(\.isNumber)) ?? 0
    }

    private func lineList(from text: String) -> [String] {
        text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

struct ManualMealEntrySheet: View {
    let onSave: (Data, MealNutritionEstimate) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedMealPhoto: PhotosPickerItem?
    @State private var imageData = Data()
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var fiber = ""
    @State private var sugar = ""
    @State private var summary = ""
    @State private var notes = ""

    private var canSave: Bool {
        !imageData.isEmpty && intValue(calories) > 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    PhotosPicker(selection: $selectedMealPhoto, matching: .images) {
                        ZStack {
                            if let image = UIImage(data: imageData) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                VStack(spacing: 10) {
                                    Image(systemName: "camera.fill")
                                        .font(.title.weight(.bold))
                                        .foregroundStyle(AppTheme.accent)

                                    Text(localizedAppString("Add Meal Photo"))
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(AppTheme.text)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 190)
                        .background(AppTheme.fieldBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 12) {
                        Text(localizedAppString("Calories"))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.text)

                        NutrientNumberInput(title: "Calories", unit: "kcal", text: $calories)
                    }
                    .nutritionEditCard()

                    VStack(alignment: .leading, spacing: 12) {
                        Text(localizedAppString("Macronutrients"))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.text)

                        NutrientNumberInput(title: "Protein", unit: "g", text: $protein)
                        NutrientNumberInput(title: "Carbs", unit: "g", text: $carbs)
                        NutrientNumberInput(title: "Fat", unit: "g", text: $fat)
                    }
                    .nutritionEditCard()

                    VStack(alignment: .leading, spacing: 12) {
                        Text(localizedAppString("More Nutrition Details"))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.text)

                        NutrientNumberInput(title: "Fiber", unit: "g", text: $fiber)
                        NutrientNumberInput(title: "Sugar", unit: "g", text: $sugar)
                    }
                    .nutritionEditCard()

                    VStack(alignment: .leading, spacing: 12) {
                        Text(localizedAppString("Meal Notes"))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.text)

                        TextField(localizedAppString("Meal summary"), text: $summary, axis: .vertical)
                            .lineLimit(3...5)
                            .nutritionTextFieldStyle()

                        TextField(localizedAppString("Notes"), text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                            .nutritionTextFieldStyle()
                    }
                    .nutritionEditCard()
                }
                .padding(20)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(localizedAppString("Add Meal Manually"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(localizedAppString("Cancel")) {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.accent)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(localizedAppString("Save")) {
                        onSave(imageData, makeEstimate())
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(canSave ? AppTheme.accent : .secondary)
                    .disabled(!canSave)
                }
            }
            .task(id: selectedMealPhoto) {
                await loadSelectedMealPhoto()
            }
        }
    }

    private func loadSelectedMealPhoto() async {
        guard let selectedMealPhoto else { return }

        do {
            if let data = try await selectedMealPhoto.loadTransferable(type: Data.self) {
                await MainActor.run {
                    imageData = data
                }
            }
        } catch {
            // Keep the current draft if photo loading fails.
        }
    }

    private func makeEstimate() -> MealNutritionEstimate {
        let trimmedSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        return MealNutritionEstimate(
            calories: intValue(calories),
            protein: intValue(protein),
            carbs: intValue(carbs),
            fat: intValue(fat),
            fiber: intValue(fiber),
            sugar: intValue(sugar),
            confidence: "manual",
            summary: trimmedSummary.isEmpty ? localizedAppString("Manually entered meal.") : trimmedSummary,
            recommendations: [],
            notes: trimmedNotes.isEmpty ? [] : [trimmedNotes]
        )
    }

    private func intValue(_ text: String) -> Int {
        Int(text.filter(\.isNumber)) ?? 0
    }
}

struct NutrientNumberInput: View {
    let title: String
    let unit: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Text(LocalizedStringKey(title))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.text)

            Spacer()

            TextField("0", text: numericText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .font(.headline.weight(.bold))
                .frame(width: 90)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(AppTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text(unit)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .leading)
        }
    }

    private var numericText: Binding<String> {
        Binding(
            get: { text },
            set: { text = $0.filter(\.isNumber) }
        )
    }
}

private extension View {
    func nutritionEditCard() -> some View {
        self
            .padding(14)
            .background(AppTheme.panel)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 6)
    }

    func nutritionTextFieldStyle() -> some View {
        self
            .padding(12)
            .background(AppTheme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    func skinSectionCard() -> some View {
        self
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.035), radius: 10, x: 0, y: 5)
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

                    Text(localizedAppString("Upload Meal Photo"))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.text)

                    Text(localizedAppString("Breakfast, lunch, dinner, or snack"))
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
                    Text(localizedAppString("AI Estimate"))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.text)

                    Text(LocalizedStringKey(estimate.confidence))
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

                        Text(localizedSavedAIText(note))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

struct MealHistoryView: View {
    let savedMeals: [SavedMealEstimate]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            if savedMeals.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)

                    Text(localizedAppString("No saved meals yet"))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.text)

                    Text(localizedAppString("Saved nutrient estimates will appear here."))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 80)
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(savedMeals) { meal in
                        NavigationLink {
                            MealHistoryDetailView(savedMeal: meal)
                        } label: {
                            MealHistoryThumbnail(savedMeal: meal)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(localizedAppString("Meal History"))
    }
}

struct MealHistoryThumbnail: View {
    let savedMeal: SavedMealEstimate

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let image = UIImage(data: savedMeal.imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 150)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppTheme.fieldBackground)
                    .frame(height: 150)
                    .overlay {
                        Image(systemName: "fork.knife")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(AppTheme.accent)
                    }
            }

            Text(localizedDateString(savedMeal.savedAt, dateStyle: .medium, timeStyle: .short))
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)

            Text("\(savedMeal.estimate.calories) kcal")
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.text)
        }
        .padding(10)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 6)
    }
}

struct MealHistoryDetailView: View {
    let savedMeal: SavedMealEstimate
    @State private var activeMealPDF: MealPDFShareItem?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let image = UIImage(data: savedMeal.imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 250)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                Text(localizedDateString(savedMeal.savedAt, dateStyle: .full, timeStyle: .short))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)

                Button {
                    exportSavedMealPDF()
                } label: {
                    Label(localizedAppString("Export as PDF"), systemImage: "doc.richtext.fill")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                MealNutritionEstimateView(estimate: savedMeal.estimate)
            }
            .padding(20)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(localizedAppString("Meal Details"))
        .sheet(item: $activeMealPDF) { item in
            PDFShareSheet(url: item.url)
        }
    }

    private func exportSavedMealPDF() {
        guard let url = MealPDFExporter.export(
            imageData: savedMeal.imageData,
            estimate: savedMeal.estimate,
            savedAt: savedMeal.savedAt
        ) else {
            return
        }

        activeMealPDF = MealPDFShareItem(url: url)
    }
}

struct MealReportTextSection: View {
    let title: String
    let icon: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(LocalizedStringKey(title), systemImage: icon)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.text)

            if text.isEmpty {
                Text(localizedAppString("No summary available."))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(localizedSavedAIText(text))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
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
        items.isEmpty ? [localizedAppString("No recommendations available.")] : items
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(LocalizedStringKey(title), systemImage: icon)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.text)

            ForEach(displayItems, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.accent)

                    Text(localizedSavedAIText(item))
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
                        Text(localizedAppString("Parent Account"))
                            .font(.title3.weight(.bold))

                        InfoRow(title: "Parent Username", value: user.nickname)
                        InfoRow(title: "Parent Email", value: user.email)
                        InfoRow(title: "Account Type", value: localizedAppString("Parent"))
                    }
                    .authPanel()

                    NavigationLink {
                        SettingsMenuView()
                    } label: {
                        Text(localizedAppString("Settings"))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.accent)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.accent.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(alignment: .trailing) {
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.black))
                                    .foregroundStyle(AppTheme.accent)
                                    .padding(.trailing, 16)
                            }
                    }
                    .buttonStyle(.plain)

                    Button(role: .destructive, action: logout) {
                        Text(localizedAppString("Log Out"))
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
            .navigationTitle(localizedAppString("Profile"))
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

struct SettingsMenuView: View {
    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.english.rawValue
    @State private var isShowingLanguagePicker = false

    private var selectedLanguage: AppLanguage {
        AppLanguage(code: languageCode)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Button {
                    isShowingLanguagePicker = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "globe")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.accent)
                            .frame(width: 34, height: 34)
                            .background(AppTheme.accent.opacity(0.12))
                            .clipShape(Circle())

                        Text(localizedAppString("Language"))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.text)

                        Spacer()

                        Text(selectedLanguage.displayName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.black))
                            .foregroundStyle(.secondary)
                    }
                    .padding(14)
                    .background(AppTheme.fieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(20)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(localizedAppString("Settings"))
        .confirmationDialog(localizedAppString("Language"), isPresented: $isShowingLanguagePicker, titleVisibility: .visible) {
            Button(localizedAppString("English")) {
                languageCode = AppLanguage.english.rawValue
            }

            Button("中文") {
                languageCode = AppLanguage.chinese.rawValue
            }

            Button(localizedAppString("Cancel"), role: .cancel) {}
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
                .accessibilityLabel(localizedAppString("Change child profile picture"))
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
                .accessibilityLabel(localizedAppString("Open child basic information"))

                Text(localizedAppString("Parent account for your child's care."))
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
                Text(LocalizedStringKey(title))
                    .font(.largeTitle.weight(.bold))

                Text(LocalizedStringKey(subtitle))
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

            Text(LocalizedStringKey(title))
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
                Text(LocalizedStringKey(title))
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
                Text(LocalizedStringKey(title))
                    .fontWeight(.semibold)

                Text(LocalizedStringKey(detail))
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
            Text(LocalizedStringKey(title))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.text)

            TextField(LocalizedStringKey(placeholder), text: $text, axis: axis)
                .textInputAutocapitalization(.never)
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
                    Text(localizedAppString("Parent Account"))
                        .font(.headline.weight(.bold))

                    InfoRow(title: "Parent Username", value: user.nickname)
                    InfoRow(title: "Parent Email", value: user.email)
                    InfoRow(title: "Account Type", value: localizedAppString("Parent"))
                }
                .authPanel()

                VStack(alignment: .leading, spacing: 16) {
                    Text(localizedAppString("Child Profile"))
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
            do {
                try await AuthAPI().syncAppData(
                    userId: user.id,
                    childProfile: profile,
                    healthLogs: nil
                )
                print("Child profile synced for user \(user.id).")
            } catch {
                print("Child profile sync failed for user \(user.id): \(error.localizedDescription)")
            }
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(LocalizedStringKey(title))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}
