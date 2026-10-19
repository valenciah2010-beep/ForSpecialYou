import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

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

