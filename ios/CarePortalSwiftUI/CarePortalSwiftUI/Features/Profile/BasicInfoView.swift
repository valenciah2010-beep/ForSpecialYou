import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

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

