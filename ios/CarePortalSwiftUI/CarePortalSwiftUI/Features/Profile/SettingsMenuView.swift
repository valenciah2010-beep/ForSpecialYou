import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

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

