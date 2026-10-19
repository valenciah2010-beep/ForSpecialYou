import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

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
                            .padding(.horizontal, 14)
                            .frame(height: 34)
                            .background(AppTheme.accent.opacity(0.10))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    ToolbarCloseButton {
                        dismiss()
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

