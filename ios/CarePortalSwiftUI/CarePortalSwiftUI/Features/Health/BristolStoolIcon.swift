import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct BristolStoolIcon: View {
    let type: Int

    var body: some View {
        BundledPNGImage(name: "BristolStoolType\(type)")
    }
}

