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
    @AppStorage private var profileImageData: Data
    @AppStorage private var quickLogSelection: String
    @AppStorage private var healthLogData: Data
    @State private var isQuickLogEditorPresented = false
    @State private var activeLogInput: HealthLogInputTarget?
    @State private var activeSeizureTimer: QuickLogOption?
    @State private var activePainLog: QuickLogOption?
    @State private var draggingQuickLogID: String?

    init(user: CarePortalUser) {
        self.user = user
        self._childName = AppStorage(wrappedValue: "", "profile.\(user.id).fullName")
        self._profileImageData = AppStorage(wrappedValue: Data(), "profile.\(user.id).profileImageData")
        self._quickLogSelection = AppStorage(
            wrappedValue: QuickLogOption.defaultSelectionString,
            "health.\(user.id).quickLogSelection"
        )
        self._healthLogData = AppStorage(wrappedValue: Data(), "health.\(user.id).logData")
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

                                Text("Trends")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(AppTheme.accent)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Open quick-log trends")

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

                    DashboardSectionTitle("Daily Snapshot")

                    LazyVGrid(columns: snapshotColumns, spacing: 10) {
                        ForEach(SnapshotOption.all) { option in
                            SnapshotCard(option: option) {
                                activeLogInput = .snapshot(option)
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
            .sheet(item: $activeSeizureTimer) { option in
                SeizureTimerSheet(option: option) { entry in
                    saveLogEntry(entry)
                }
            }
            .sheet(item: $activePainLog) { option in
                PainLogEntrySheet(option: option) { entry in
                    saveLogEntry(entry)
                }
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

    private func saveLogEntry(_ entry: HealthLogEntry) {
        var updatedEntries = logEntries
        updatedEntries.append(entry)
        updatedEntries.sort { $0.timestamp < $1.timestamp }

        if let data = try? JSONEncoder().encode(updatedEntries) {
            healthLogData = data
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
        QuickLogOption(id: "medsFood", title: "Meds/Food", icon: "pills.fill", tint: Color(red: 0.38, green: 0.75, blue: 0.55))
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
            value: "7/9 hrs",
            detail: "Good night",
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

                HStack {
                    Spacer()
                    Image(systemName: option.icon)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(option.tint)
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(option.value)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text(option.detail)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                ProgressView(value: option.progress)
                    .tint(option.tint)
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

struct PainLogEntrySheet: View {
    @Environment(\.dismiss) private var dismiss

    let option: QuickLogOption
    let onSave: (HealthLogEntry) -> Void

    @State private var useCurrentTime = true
    @State private var timestamp = Date()
    @State private var severity = 3.0
    @State private var selectedSide: PainBodySide = .front
    @State private var selectedLocation = ""
    @State private var shortComment = ""
    @State private var indicators = ""

    private var displayLocation: String {
        selectedLocation.isEmpty ? "Tap a body area" : selectedLocation
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
                            selectedSide: $selectedSide,
                            selectedLocation: $selectedLocation,
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
        let location = selectedLocation.trimmingCharacters(in: .whitespacesAndNewlines)
        let savedLocation = location.isEmpty ? "Pain location not selected" : "\(selectedSide.rawValue): \(location)"
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

struct PainLocation: Identifiable {
    let id: String
    let side: PainBodySide
    let label: String
    let x: Double
    let y: Double
}

struct PainBodySelector: View {
    @Binding var selectedSide: PainBodySide
    @Binding var selectedLocation: String
    let tint: Color

    private let locations: [PainLocation] = [
        PainLocation(id: "front-head", side: .front, label: "Head", x: 0.50, y: 0.12),
        PainLocation(id: "front-throat", side: .front, label: "Throat", x: 0.50, y: 0.23),
        PainLocation(id: "front-chest", side: .front, label: "Chest", x: 0.50, y: 0.34),
        PainLocation(id: "front-belly", side: .front, label: "Belly", x: 0.50, y: 0.47),
        PainLocation(id: "front-left-arm", side: .front, label: "Left arm", x: 0.31, y: 0.39),
        PainLocation(id: "front-right-arm", side: .front, label: "Right arm", x: 0.69, y: 0.39),
        PainLocation(id: "front-left-hand", side: .front, label: "Left hand", x: 0.24, y: 0.58),
        PainLocation(id: "front-right-hand", side: .front, label: "Right hand", x: 0.76, y: 0.58),
        PainLocation(id: "front-left-leg", side: .front, label: "Left leg", x: 0.42, y: 0.75),
        PainLocation(id: "front-right-leg", side: .front, label: "Right leg", x: 0.58, y: 0.75),
        PainLocation(id: "back-head", side: .back, label: "Head", x: 0.50, y: 0.12),
        PainLocation(id: "back-neck", side: .back, label: "Neck", x: 0.50, y: 0.23),
        PainLocation(id: "back-upper", side: .back, label: "Upper back", x: 0.50, y: 0.34),
        PainLocation(id: "back-lower", side: .back, label: "Lower back", x: 0.50, y: 0.49),
        PainLocation(id: "back-left-shoulder", side: .back, label: "Left shoulder", x: 0.34, y: 0.31),
        PainLocation(id: "back-right-shoulder", side: .back, label: "Right shoulder", x: 0.66, y: 0.31),
        PainLocation(id: "back-left-hip", side: .back, label: "Left hip", x: 0.42, y: 0.60),
        PainLocation(id: "back-right-hip", side: .back, label: "Right hip", x: 0.58, y: 0.60),
        PainLocation(id: "back-left-leg", side: .back, label: "Left leg", x: 0.42, y: 0.78),
        PainLocation(id: "back-right-leg", side: .back, label: "Right leg", x: 0.58, y: 0.78)
    ]

    private var visibleLocations: [PainLocation] {
        locations.filter { $0.side == selectedSide }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pain Location")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.text)

            Picker("Body side", selection: $selectedSide) {
                ForEach(PainBodySide.allCases) { side in
                    Text(side.rawValue).tag(side)
                }
            }
            .pickerStyle(.segmented)

            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppTheme.fieldBackground)

                GeometryReader { proxy in
                    ZStack {
                        PainBodySilhouette(side: selectedSide, tint: tint)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                        ForEach(visibleLocations) { location in
                            Button {
                                selectedLocation = location.label
                            } label: {
                                Image(systemName: selectedLocation == location.label ? "checkmark" : "plus")
                                    .font(.caption.weight(.black))
                                    .foregroundStyle(selectedLocation == location.label ? .white : tint)
                                    .frame(width: 26, height: 26)
                                    .background(selectedLocation == location.label ? tint : Color.white)
                                    .clipShape(Circle())
                                    .shadow(color: Color.black.opacity(0.12), radius: 5, x: 0, y: 2)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(location.label) pain location")
                            .position(
                                x: proxy.size.width * location.x,
                                y: proxy.size.height * location.y
                            )
                        }
                    }
                }
                .padding(12)
            }
            .frame(height: 360)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Text(selectedLocation.isEmpty ? "No location selected" : "\(selectedSide.rawValue): \(selectedLocation)")
                .font(.caption.weight(.bold))
                .foregroundStyle(selectedLocation.isEmpty ? .secondary : tint)
        }
    }
}

struct PainBodySilhouette: View {
    let side: PainBodySide
    let tint: Color

    var body: some View {
        ZStack {
            Capsule()
                .fill(tint.opacity(0.18))
                .frame(width: 92, height: 150)
                .offset(y: -34)

            Circle()
                .fill(tint.opacity(0.22))
                .frame(width: 56, height: 56)
                .offset(y: -146)

            Capsule()
                .fill(tint.opacity(0.18))
                .frame(width: 30, height: 136)
                .rotationEffect(.degrees(-17))
                .offset(x: -68, y: -38)

            Capsule()
                .fill(tint.opacity(0.18))
                .frame(width: 30, height: 136)
                .rotationEffect(.degrees(17))
                .offset(x: 68, y: -38)

            Capsule()
                .fill(tint.opacity(0.18))
                .frame(width: 34, height: 150)
                .rotationEffect(.degrees(7))
                .offset(x: -24, y: 118)

            Capsule()
                .fill(tint.opacity(0.18))
                .frame(width: 34, height: 150)
                .rotationEffect(.degrees(-7))
                .offset(x: 24, y: 118)

            if side == .back {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(tint.opacity(0.38), lineWidth: 2)
                    .frame(width: 44, height: 92)
                    .offset(y: -34)
            } else {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(tint.opacity(0.10))
                    .frame(width: 46, height: 58)
                    .offset(y: -58)
            }
        }
    }
}

struct SeizureTimerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let option: QuickLogOption
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
            seizureType = "Seizure Type"
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
                VStack(alignment: .leading, spacing: 6) {
                    Text("Quick-log Trends")
                        .font(.largeTitle.weight(.bold))

                    Text("Chart previews for the quick-log buttons selected on the dashboard.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if options.isEmpty {
                    Text("Choose quick-log buttons on the dashboard to see trends here.")
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
        .navigationTitle("Trends")
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
        Button {
        } label: {
            VStack(alignment: .leading, spacing: 14) {
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
        .buttonStyle(.plain)
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

                    if !profileImageData.isEmpty {
                        Button("Remove Child Picture", role: .destructive) {
                            profileImageData = Data()
                        }
                        .font(.subheadline.weight(.semibold))
                    }

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
                VStack(alignment: .leading, spacing: 6) {
                    Text("Child Basic Info")
                        .font(.largeTitle.weight(.bold))

                    Text("A parent-managed snapshot of your child's needs and care details.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

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
        .navigationTitle("Child Info")
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
        return trimmed.isEmpty ? "Not added" : trimmed
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
