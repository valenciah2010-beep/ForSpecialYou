import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct QuickLogDropDelegate: DropDelegate {
    let targetOption: QuickLogOption
    let selectedOptions: [QuickLogOption]
    @Binding var draggingQuickLogID: String?
    let moveAction: (String, String) -> Void

    func dropEntered(info: DropInfo) {
        guard let draggingQuickLogID,
              draggingQuickLogID != targetOption.id,
              selectedOptions.contains(where: { $0.id == draggingQuickLogID }) else {
            return
        }

        moveAction(draggingQuickLogID, targetOption.id)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingQuickLogID = nil
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func dropExited(info: DropInfo) {
        if info.location == .zero {
            draggingQuickLogID = nil
        }
    }
}

