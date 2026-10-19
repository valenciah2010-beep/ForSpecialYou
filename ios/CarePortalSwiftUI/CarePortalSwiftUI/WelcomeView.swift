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
            DiagnosisView(user: user)
                .tabItem {
                    Label(localizedAppString("Diagnosis"), systemImage: "stethoscope")
                }
                .tag(0)

            BasicHealthView(user: user) {
                selectedTab = 4
            }
                .tabItem {
                    Label(localizedAppString("Health"), systemImage: "heart.text.square")
                }
                .tag(1)

            TherapyTrackingView(user: user)
                .tabItem {
                    Label(localizedAppString("Therapy"), systemImage: "figure.mind.and.body")
                }
                .tag(2)

            NutrientView(user: user)
                .tabItem {
                    Label(localizedAppString("Nutrient"), systemImage: "leaf")
                }
                .tag(3)

            ProfileView(user: user, logout: logout)
                .tabItem {
                    Label(localizedAppString("Profile"), systemImage: "person.crop.circle")
                }
                .tag(4)
        }
        .tint(AppTheme.accent)
    }
}
