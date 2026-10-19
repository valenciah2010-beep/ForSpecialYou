import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct CyclicVomitingPatternsData: Codable {
    var episodesPastYear = ""
    var episodeInterval = ""
    var episodeDuration = ""
    var historicalTriggers: [String] = []
    var otherHistoricalTriggers = ""
    var prodromalSymptoms: [String] = []
    var otherProdromalSymptoms = ""
    var episodeSymptoms: [String] = []
    var otherEpisodeSymptoms = ""
    var postdromalSymptoms: [String] = []
    var otherPostdromalSymptoms = ""
    var heightCm = ""
    var heightUnit: String? = "cm"
    var weightKg = ""
    var weightUnit: String? = "Kg"
    var qualityOfLifeAgeGroup = ""
    var qualityOfLifeResponses: [String: Int] = [:]

    enum CodingKeys: String, CodingKey {
        case episodesPastYear
        case episodeInterval
        case episodeDuration
        case historicalTriggers
        case otherHistoricalTriggers
        case prodromalSymptoms
        case otherProdromalSymptoms
        case episodeSymptoms
        case otherEpisodeSymptoms
        case postdromalSymptoms
        case otherPostdromalSymptoms
        case heightCm
        case heightUnit
        case weightKg
        case weightUnit
        case qualityOfLifeAgeGroup
        case qualityOfLifeResponses
    }

    init(
        episodesPastYear: String = "",
        episodeInterval: String = "",
        episodeDuration: String = "",
        historicalTriggers: [String] = [],
        otherHistoricalTriggers: String = "",
        prodromalSymptoms: [String] = [],
        otherProdromalSymptoms: String = "",
        episodeSymptoms: [String] = [],
        otherEpisodeSymptoms: String = "",
        postdromalSymptoms: [String] = [],
        otherPostdromalSymptoms: String = "",
        heightCm: String = "",
        heightUnit: String? = "cm",
        weightKg: String = "",
        weightUnit: String? = "Kg",
        qualityOfLifeAgeGroup: String = "",
        qualityOfLifeResponses: [String: Int] = [:]
    ) {
        self.episodesPastYear = episodesPastYear
        self.episodeInterval = episodeInterval
        self.episodeDuration = episodeDuration
        self.historicalTriggers = historicalTriggers
        self.otherHistoricalTriggers = otherHistoricalTriggers
        self.prodromalSymptoms = prodromalSymptoms
        self.otherProdromalSymptoms = otherProdromalSymptoms
        self.episodeSymptoms = episodeSymptoms
        self.otherEpisodeSymptoms = otherEpisodeSymptoms
        self.postdromalSymptoms = postdromalSymptoms
        self.otherPostdromalSymptoms = otherPostdromalSymptoms
        self.heightCm = heightCm
        self.heightUnit = heightUnit
        self.weightKg = weightKg
        self.weightUnit = weightUnit
        self.qualityOfLifeAgeGroup = qualityOfLifeAgeGroup
        self.qualityOfLifeResponses = qualityOfLifeResponses
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        episodesPastYear = try container.decodeIfPresent(String.self, forKey: .episodesPastYear) ?? ""
        episodeInterval = try container.decodeIfPresent(String.self, forKey: .episodeInterval) ?? ""
        episodeDuration = try container.decodeIfPresent(String.self, forKey: .episodeDuration) ?? ""
        historicalTriggers = try container.decodeIfPresent([String].self, forKey: .historicalTriggers) ?? []
        otherHistoricalTriggers = try container.decodeIfPresent(String.self, forKey: .otherHistoricalTriggers) ?? ""
        prodromalSymptoms = try container.decodeIfPresent([String].self, forKey: .prodromalSymptoms) ?? []
        otherProdromalSymptoms = try container.decodeIfPresent(String.self, forKey: .otherProdromalSymptoms) ?? ""
        episodeSymptoms = try container.decodeIfPresent([String].self, forKey: .episodeSymptoms) ?? []
        otherEpisodeSymptoms = try container.decodeIfPresent(String.self, forKey: .otherEpisodeSymptoms) ?? ""
        postdromalSymptoms = try container.decodeIfPresent([String].self, forKey: .postdromalSymptoms) ?? []
        otherPostdromalSymptoms = try container.decodeIfPresent(String.self, forKey: .otherPostdromalSymptoms) ?? ""
        heightCm = try container.decodeIfPresent(String.self, forKey: .heightCm) ?? ""
        heightUnit = try container.decodeIfPresent(String.self, forKey: .heightUnit) ?? "cm"
        weightKg = try container.decodeIfPresent(String.self, forKey: .weightKg) ?? ""
        weightUnit = try container.decodeIfPresent(String.self, forKey: .weightUnit) ?? "Kg"
        qualityOfLifeAgeGroup = try container.decodeIfPresent(String.self, forKey: .qualityOfLifeAgeGroup) ?? ""
        qualityOfLifeResponses = try container.decodeIfPresent([String: Int].self, forKey: .qualityOfLifeResponses) ?? [:]
    }
}

