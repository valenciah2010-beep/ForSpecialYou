import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct CyclicVomitingBackgroundData: Codable {
    var familyHistory: [String] = []
    var surgicalHistory: [String] = []
    var otherSurgery: String = ""
    var onsetYear: String = ""
    var onsetMonth: String = ""
    var comorbidities: [String] = []
    var metabolismName: String = ""
    var otherComorbidity: String = ""
    var hospitalizedAtBeijingHospital: Bool?
    var currentMedications: [String] = []
    var otherCurrentMedication: String = ""
    var hadAdverseDrugReaction: Bool?
    var adverseDrugReactionDetails: String = ""
    var pastMedications: [String] = []
    var otherPastMedication: String = ""
}

