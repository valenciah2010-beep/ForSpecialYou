import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

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
    @State private var activeAccidentLog: QuickLogOption?
    @State private var activeDeescalationLog: QuickLogOption?
    @State private var activePainLog: QuickLogOption?
    @State private var activeSkinLog: QuickLogOption?
    @State private var activeMedicineLog: QuickLogOption?
    @State private var activeMoodLog: QuickLogOption?
    @State private var activeCyclicVomitingLog: QuickLogOption?
    @State private var activeSleepSnapshot: SleepSnapshotEditorTarget?
    @State private var activeDigestionSnapshot: SnapshotOption?
    @State private var activeNutritionSnapshot: SnapshotOption?
    @State private var activeMeasurementSnapshot: MeasurementSnapshotEditorTarget?
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
                                    } else if option.id == "accident" {
                                        activeAccidentLog = option
                                    } else if option.id == "deescalation" {
                                        activeDeescalationLog = option
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
                            SnapshotHistoryView(options: SnapshotOption.all + SnapshotOption.measurements, entries: logEntries)
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
                                } else if option.id == "mood" {
                                    activeMoodLog = QuickLogOption.moodSnapshotOption
                                } else {
                                    activeLogInput = .snapshot(option)
                                }
                            }
                        }
                    }

                    HStack(spacing: 10) {
                        ForEach(SnapshotOption.measurements) { option in
                            let snapshotSummary = todaysSnapshotSummary(for: option)

                            CompactSnapshotCard(
                                option: option,
                                displayValue: snapshotSummary.isLoggedToday ? snapshotSummary.value : nil
                            ) {
                                activeMeasurementSnapshot = MeasurementSnapshotEditorTarget(
                                    option: option,
                                    existingEntry: latestTodaySnapshotEntry(for: option.id)
                                )
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
            .sheet(item: $activeMeasurementSnapshot) { target in
                MeasurementSnapshotSheet(target: target) { entry in
                    saveDailySnapshotEntry(entry)
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
            .sheet(item: $activeAccidentLog) { option in
                AccidentLogEntrySheet(option: option) { entry in
                    saveLogEntry(entry)
                }
            }
            .sheet(item: $activeDeescalationLog) { option in
                DeescalationLogEntrySheet(option: option) { entry in
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

    private func saveDailySnapshotEntry(_ entry: HealthLogEntry) {
        var updatedEntries = logEntries.filter { savedEntry in
            !(savedEntry.type == .snapshot
              && savedEntry.categoryID == entry.categoryID
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

