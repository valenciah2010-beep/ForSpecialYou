import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

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

