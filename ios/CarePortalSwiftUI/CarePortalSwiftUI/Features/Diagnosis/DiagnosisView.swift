import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct DiagnosisView: View {
    let user: CarePortalUser
    @AppStorage private var selectedDiagnosisOptionData: String
    @AppStorage private var conditionData: Data
    @AppStorage private var doctorVisitData: Data
    @AppStorage private var diagnosisNoteData: Data
    @State private var isEditorPresented = false
    @State private var isConditionFormPresented = false
    @State private var isDoctorVisitFormPresented = false
    @State private var editingCondition: DiagnosisCondition?
    @State private var pendingDeleteTarget: DiagnosisDeleteTarget?

    init(user: CarePortalUser) {
        self.user = user
        self._selectedDiagnosisOptionData = AppStorage(wrappedValue: "", "diagnosis.\(user.id).selectedOptions")
        self._conditionData = AppStorage(wrappedValue: Data(), "diagnosis.\(user.id).conditions")
        self._doctorVisitData = AppStorage(wrappedValue: Data(), "diagnosis.\(user.id).doctorVisits")
        self._diagnosisNoteData = AppStorage(wrappedValue: Data(), "diagnosis.\(user.id).generalNotes")
    }

    private var selectedDiagnosisIDs: Set<String> {
        Set(selectedDiagnosisOptionData.split(separator: ",").map(String.init))
    }

    private var selectedDiagnosisOptions: [DiagnosisOption] {
        DiagnosisOption.all.filter { selectedDiagnosisIDs.contains($0.id) }
    }

    private var selectedDiagnosisBinding: Binding<Set<String>> {
        Binding {
            selectedDiagnosisIDs
        } set: { newValue in
            selectedDiagnosisOptionData = DiagnosisOption.all
                .map(\.id)
                .filter { newValue.contains($0) }
                .joined(separator: ",")
        }
    }

    private var conditions: [DiagnosisCondition] {
        get {
            guard !conditionData.isEmpty else { return [] }
            return (try? JSONDecoder().decode([DiagnosisCondition].self, from: conditionData)) ?? []
        }
        nonmutating set {
            conditionData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    private var doctorVisits: [DiagnosisDoctorVisit] {
        get {
            guard !doctorVisitData.isEmpty else { return [] }
            return (try? JSONDecoder().decode([DiagnosisDoctorVisit].self, from: doctorVisitData)) ?? []
        }
        nonmutating set {
            doctorVisitData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    private var diagnosisNotes: [DiagnosisGeneralNote] {
        get {
            guard !diagnosisNoteData.isEmpty else { return [] }
            return (try? JSONDecoder().decode([DiagnosisGeneralNote].self, from: diagnosisNoteData)) ?? []
        }
        nonmutating set {
            diagnosisNoteData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .center, spacing: 12) {
                                Image(systemName: "stethoscope")
                                    .font(.system(size: 34, weight: .semibold))
                                    .foregroundStyle(AppTheme.accent)

                                Text(localizedAppString("Diagnosis"))
                                    .font(.largeTitle.weight(.bold))
                                    .foregroundStyle(AppTheme.text)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Button {
                            isEditorPresented = true
                        } label: {
                            Text(localizedAppString("Edit"))
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(AppTheme.accent)
                                .padding(.horizontal, 14)
                                .frame(height: 38)
                                .background(AppTheme.accent.opacity(0.10))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(localizedAppString("Conditions"))
                                .font(.title2.weight(.bold))
                                .foregroundStyle(AppTheme.text)

                            Spacer()

                            Button {
                                isConditionFormPresented = true
                            } label: {
                                Image(systemName: "plus")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(AppTheme.accent)
                                    .frame(width: 38, height: 38)
                                    .background(AppTheme.accent.opacity(0.10))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(localizedAppString("Add condition"))
                        }

                        if conditions.isEmpty {
                            Text(localizedAppString("No conditions added yet."))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background(AppTheme.panel)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        } else {
                            VStack(spacing: 10) {
                                ForEach(conditions) { condition in
                                    DiagnosisSwipeRow(
                                        actions: [
                                            DiagnosisSwipeAction(title: "Edit", icon: "pencil", tint: AppTheme.accent) {
                                                editingCondition = condition
                                            },
                                            DiagnosisSwipeAction(title: "Delete", icon: "trash", tint: .red) {
                                                pendingDeleteTarget = DiagnosisDeleteTarget(kind: .condition(condition))
                                            }
                                        ]
                                    ) {
                                        Button {
                                            editingCondition = condition
                                        } label: {
                                            DiagnosisConditionCard(condition: condition)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        HStack(spacing: 10) {
                            DiagnosisSecondaryAddButton(title: "Doctor Visit", icon: "stethoscope", tint: Color(red: 0.19, green: 0.48, blue: 0.82)) {
                                isDoctorVisitFormPresented = true
                            }
                        }
                    }

                    if !selectedDiagnosisOptions.isEmpty {
                        VStack(spacing: 10) {
                            ForEach(selectedDiagnosisOptions) { option in
                                DiagnosisSwipeRow(
                                    actions: [
                                        DiagnosisSwipeAction(title: "Delete", icon: "trash", tint: .red) {
                                            pendingDeleteTarget = DiagnosisDeleteTarget(kind: .category(option))
                                        }
                                    ]
                                ) {
                                    NavigationLink {
                                        DiagnosisDetailView(userID: user.id, option: option)
                                    } label: {
                                        HStack(spacing: 14) {
                                            Text(option.emoji)
                                                .font(.title2)
                                                .frame(width: 46, height: 46)
                                                .background(AppTheme.accent.opacity(0.10))
                                                .clipShape(Circle())

                                            Text(localizedAppString(option.title))
                                                .font(.headline.weight(.bold))
                                                .foregroundStyle(AppTheme.text)
                                                .lineLimit(2)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        .padding(16)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(AppTheme.panel)
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(localizedAppString("Category"))
            .alert(item: $pendingDeleteTarget) { target in
                Alert(
                    title: Text(localizedAppString(target.titleKey)),
                    message: Text(localizedAppString(target.messageKey)),
                    primaryButton: .destructive(Text(localizedAppString("Delete"))) {
                        switch target.kind {
                        case .condition(let condition):
                            conditions = conditions.filter { $0.id != condition.id }
                        case .category(let option):
                            removeDiagnosisOption(option.id)
                        }
                        pendingDeleteTarget = nil
                    },
                    secondaryButton: .cancel(Text(localizedAppString("Cancel"))) {
                        pendingDeleteTarget = nil
                    }
                )
            }
            .sheet(isPresented: $isEditorPresented) {
                DiagnosisSelectionSheet(selectedIDs: selectedDiagnosisBinding)
            }
            .sheet(isPresented: $isConditionFormPresented) {
                DiagnosisConditionFormSheet { condition in
                    var updated = conditions
                    updated.insert(condition, at: 0)
                    conditions = updated
                    addDiagnosisOptions(condition.categoryIDs)
                    isConditionFormPresented = false
                }
            }
            .sheet(item: $editingCondition) { condition in
                DiagnosisConditionFormSheet(existingCondition: condition) { editedCondition in
                    var updated = conditions
                    if let index = updated.firstIndex(where: { $0.id == editedCondition.id }) {
                        updated[index] = editedCondition
                    } else {
                        updated.insert(editedCondition, at: 0)
                    }
                    conditions = updated
                    addDiagnosisOptions(editedCondition.categoryIDs)
                    editingCondition = nil
                }
            }
            .sheet(isPresented: $isDoctorVisitFormPresented) {
                DiagnosisDoctorVisitFormSheet { visit in
                    var updated = doctorVisits
                    updated.insert(visit, at: 0)
                    doctorVisits = updated
                    addDiagnosisOptions(visit.categoryIDs)
                    isDoctorVisitFormPresented = false
                }
            }
        }
    }

    private func removeDiagnosisOption(_ id: String) {
        var updatedIDs = Set(selectedDiagnosisOptionData.split(separator: ",").map(String.init))
        updatedIDs.remove(id)
        selectedDiagnosisOptionData = DiagnosisOption.all
            .map(\.id)
            .filter { updatedIDs.contains($0) }
            .joined(separator: ",")
    }

    private func addDiagnosisOptions(_ ids: [String]) {
        var updatedIDs = Set(selectedDiagnosisOptionData.split(separator: ",").map(String.init))
        updatedIDs.formUnion(ids)
        selectedDiagnosisOptionData = DiagnosisOption.all
            .map(\.id)
            .filter { updatedIDs.contains($0) }
            .joined(separator: ",")
    }
}

