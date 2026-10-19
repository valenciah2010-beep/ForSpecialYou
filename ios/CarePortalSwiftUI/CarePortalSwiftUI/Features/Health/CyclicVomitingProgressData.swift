import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct CyclicVomitingProgressData: Codable {
    var startTime = Date()
    var endTime = Date()
    var hospitalized: Bool?
    var triggers: [String] = []
    var otherTriggers = ""
    var beforeSymptoms: [String] = []
    var otherBeforeSymptoms = ""
    var duringSymptoms: [String] = []
    var otherDuringSymptoms = ""
    var recoverySymptoms: [String] = []
    var otherRecoverySymptoms = ""
    var vomitingActsPerDay = 1
    var medications: [String] = []
    var otherMedication = ""
}

