import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct MealPhotoSourceSheet: View {
    @Binding var selectedMealPhoto: PhotosPickerItem?
    let cameraAvailable: Bool
    let takePhoto: () -> Void
    let cameraUnavailable: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 12) {
            Capsule()
                .fill(Color.secondary.opacity(0.25))
                .frame(width: 42, height: 5)
                .padding(.top, 4)

            Text(localizedAppString("Meal Photo"))
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.text)

            Button {
                dismiss()
                if cameraAvailable {
                    takePhoto()
                } else {
                    cameraUnavailable()
                }
            } label: {
                Label(localizedAppString("Take Photo"), systemImage: "camera.fill")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(cameraAvailable ? AppTheme.accent : Color.gray.opacity(0.55))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            PhotosPicker(selection: $selectedMealPhoto, matching: .images) {
                Label(localizedAppString("Choose from Library"), systemImage: "photo.on.rectangle")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.accent.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(20)
        .background(AppTheme.background.ignoresSafeArea())
        .onChange(of: selectedMealPhoto) { _, newValue in
            if newValue != nil {
                dismiss()
            }
        }
    }
}

