import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct MedicationSchedule: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var nickname: String
    var mode: MedicationScheduleMode
    var dailyTimes: [MedicationDayTime]
    var weeklyDays: [MedicationWeekday]
    var weeklyTimes: [MedicationDayTime]
    var doses: [String: String]
    var clockTimes: [String: String]
    var medicineType: String
    var amount: String
    var unit: String
    var duration: String
    var startDate: Date
    var intervalDays: Int
    var prescribingDoctor: String
    var instructions: String

    static func empty() -> MedicationSchedule {
        MedicationSchedule(
            id: UUID(),
            name: "",
            nickname: "",
            mode: .daily,
            dailyTimes: [],
            weeklyDays: [],
            weeklyTimes: [],
            doses: [:],
            clockTimes: [:],
            medicineType: "Round Tablet",
            amount: "",
            unit: "Tablet(s)",
            duration: "",
            startDate: Date(),
            intervalDays: 2,
            prescribingDoctor: "",
            instructions: ""
        )
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case nickname
        case mode
        case dailyTimes
        case weeklyDays
        case weeklyTimes
        case doses
        case clockTimes
        case medicineType
        case amount
        case unit
        case duration
        case startDate
        case intervalDays
        case prescribingDoctor
        case instructions
    }

    init(
        id: UUID,
        name: String,
        nickname: String,
        mode: MedicationScheduleMode,
        dailyTimes: [MedicationDayTime],
        weeklyDays: [MedicationWeekday],
        weeklyTimes: [MedicationDayTime],
        doses: [String: String],
        clockTimes: [String: String],
        medicineType: String,
        amount: String,
        unit: String,
        duration: String,
        startDate: Date,
        intervalDays: Int,
        prescribingDoctor: String,
        instructions: String
    ) {
        self.id = id
        self.name = name
        self.nickname = nickname
        self.mode = mode
        self.dailyTimes = dailyTimes
        self.weeklyDays = weeklyDays
        self.weeklyTimes = weeklyTimes
        self.doses = doses
        self.clockTimes = clockTimes
        self.medicineType = medicineType
        self.amount = amount
        self.unit = unit
        self.duration = duration
        self.startDate = startDate
        self.intervalDays = intervalDays
        self.prescribingDoctor = prescribingDoctor
        self.instructions = instructions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        nickname = try container.decode(String.self, forKey: .nickname)
        mode = try container.decode(MedicationScheduleMode.self, forKey: .mode)
        dailyTimes = try container.decode([MedicationDayTime].self, forKey: .dailyTimes)
        weeklyDays = try container.decode([MedicationWeekday].self, forKey: .weeklyDays)
        weeklyTimes = try container.decode([MedicationDayTime].self, forKey: .weeklyTimes)
        doses = try container.decode([String: String].self, forKey: .doses)
        clockTimes = try container.decodeIfPresent([String: String].self, forKey: .clockTimes) ?? [:]
        medicineType = try container.decodeIfPresent(String.self, forKey: .medicineType) ?? "Round Tablet"
        amount = try container.decodeIfPresent(String.self, forKey: .amount) ?? ""
        unit = try container.decodeIfPresent(String.self, forKey: .unit) ?? "Tablet(s)"
        duration = try container.decodeIfPresent(String.self, forKey: .duration) ?? ""
        startDate = try container.decodeIfPresent(Date.self, forKey: .startDate) ?? Date()
        intervalDays = try container.decodeIfPresent(Int.self, forKey: .intervalDays) ?? 2
        prescribingDoctor = try container.decodeIfPresent(String.self, forKey: .prescribingDoctor) ?? ""
        instructions = try container.decodeIfPresent(String.self, forKey: .instructions) ?? ""
    }

    var displayName: String {
        let nicknameText = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let nameText = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return nicknameText.isEmpty ? nameText : nicknameText
    }

    var legalName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func dose(for day: MedicationWeekday?, time: MedicationDayTime) -> String {
        let key = doseKey(day: mode == .weekly ? day : nil, time: time)
        return doses[key, default: ""].trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func clockTime(for day: MedicationWeekday?, time: MedicationDayTime) -> String {
        let key = doseKey(day: mode == .weekly ? day : nil, time: time)
        return clockTimes[key, default: time.defaultClockTime]
    }

    func clockTimeText(for day: MedicationWeekday?, time: MedicationDayTime) -> String {
        MedicationTimeFormatting.displayText(for: clockTime(for: day, time: time))
    }

    func clockTimeMinutes(for day: MedicationWeekday?, time: MedicationDayTime) -> Int {
        MedicationTimeFormatting.minutes(for: clockTime(for: day, time: time))
    }

    func doseKey(day: MedicationWeekday?, time: MedicationDayTime) -> String {
        if let day {
            return "\(day.rawValue).\(time.rawValue)"
        }

        return time.rawValue
    }
}

