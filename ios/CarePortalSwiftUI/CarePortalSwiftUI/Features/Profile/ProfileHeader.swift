import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

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
                .accessibilityLabel(localizedAppString("Change child profile picture"))
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
                .accessibilityLabel(localizedAppString("Open child basic information"))

                Text(localizedAppString("Parent account for your child's care."))
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

