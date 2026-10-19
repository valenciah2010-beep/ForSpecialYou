import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct BundledPNGImage: View {
    let name: String

    var body: some View {
        if let image = bundledImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(AppTheme.fieldBackground)
        }
    }

    private var bundledImage: UIImage? {
        if let url = Bundle.main.url(forResource: name, withExtension: "png"),
           let image = UIImage(contentsOfFile: url.path) {
            return image
        }

        return UIImage(named: name) ?? UIImage(named: "\(name).png")
    }
}

