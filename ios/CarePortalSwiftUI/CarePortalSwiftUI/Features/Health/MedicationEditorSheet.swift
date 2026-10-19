import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct MedicationEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: (MedicationSchedule) -> Void

    @State private var draft: MedicationSchedule
    @State private var isMultipleDoseMode: Bool
    @State private var hasSelectedScheduleFrequency: Bool
    @State private var doseLimitMessage = ""

    init(medication: MedicationSchedule, onSave: @escaping (MedicationSchedule) -> Void) {
        self.onSave = onSave
        var initialMedication = medication
        if initialMedication.amount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let existingDose = initialMedication.doses.values.first?.trimmingCharacters(in: .whitespacesAndNewlines),
           !existingDose.isEmpty {
            initialMedication.amount = existingDose
        }
        self._draft = State(initialValue: initialMedication)
        self._isMultipleDoseMode = State(initialValue: initialMedication.dailyTimes.count > 3 || initialMedication.weeklyTimes.count > 3)
        self._hasSelectedScheduleFrequency = State(initialValue: !initialMedication.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || initialMedication.mode != .daily || !initialMedication.dailyTimes.isEmpty || !initialMedication.weeklyDays.isEmpty || !initialMedication.weeklyTimes.isEmpty)
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

                if isMultipleDoseMode || selectedDoseSlots.count > 3 {
                    Button {
                        addDoseSlot()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.headline.weight(.bold))

                            Text(localizedAppString("Add Dose"))
                                .font(.subheadline.weight(.bold))
                        }
                        .foregroundStyle(AppTheme.accent)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(AppTheme.panel)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(AppTheme.accent.opacity(0.14), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }

                if !doseLimitMessage.isEmpty {
                    Text(doseLimitMessage)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
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
        guard hasSelectedScheduleFrequency else {
            return "Frequency"
        }

        switch draft.mode {
        case .intervalDays:
            return "Every X days"
        default:
            return draft.mode.title
        }
    }

    private var doseFrequencyTitle: String {
        if isMultipleDoseMode && selectedDoseSlots.count >= 3 {
            return "Multiple times a day"
        }

        switch selectedDoseSlots.count {
        case 1:
            return "Once a day"
        case 2:
            return "Twice a day"
        case 3:
            return "Three times a day"
        default:
            return "Multiple times a day"
        }
    }

    private func applyDoseFrequency(_ frequency: String) {
        doseLimitMessage = ""
        switch frequency {
        case "Once a day":
            isMultipleDoseMode = false
            setDoseSlots([.morning])
        case "Twice a day":
            isMultipleDoseMode = false
            setDoseSlots([.morning, .evening])
        case "Three times a day":
            isMultipleDoseMode = false
            setDoseSlots([.morning, .noon, .evening])
        case "Multiple times a day":
            isMultipleDoseMode = true
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

    private func addDoseSlot() {
        let currentSlots = sortedTimes(selectedDoseSlots)
        guard currentSlots.count < MedicationDayTime.allCases.count,
              let nextSlot = MedicationDayTime.allCases.first(where: { !currentSlots.contains($0) }) else {
            doseLimitMessage = localizedAppString("You hit the maximum number of doses for one day.")
            return
        }

        doseLimitMessage = ""
        isMultipleDoseMode = true
        setDoseSlots(currentSlots + [nextSlot])
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
                            showsClearButton: true,
                            background: MedicationFormStyle.background
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
                                hasSelectedScheduleFrequency = true
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
                ToolbarItem(placement: .principal) {
                    Text(LocalizedStringKey(draft.legalName.isEmpty ? "Add Medication" : "Edit Medication"))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppTheme.text)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    ToolbarCloseButton {
                        dismiss()
                    }
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

