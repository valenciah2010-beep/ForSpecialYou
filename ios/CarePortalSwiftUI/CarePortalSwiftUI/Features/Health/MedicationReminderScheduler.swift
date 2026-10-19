import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

enum MedicationReminderScheduler {
    private static let identifierPrefix = "medicine-reminder."
    private static let maxPendingNotifications = 60
    private static let horizonDays = 60

    static func reschedule(medications: [MedicationSchedule], calendar: Calendar = .current) {
        let center = UNUserNotificationCenter.current()

        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }

            center.getPendingNotificationRequests { existingRequests in
                let oldIDs = existingRequests
                    .map(\.identifier)
                    .filter { $0.hasPrefix(identifierPrefix) }

                if !oldIDs.isEmpty {
                    center.removePendingNotificationRequests(withIdentifiers: oldIDs)
                }

                let requests = notificationRequests(for: medications, calendar: calendar)
                requests.prefix(maxPendingNotifications).forEach { request in
                    center.add(request)
                }
            }
        }
    }

    private static func notificationRequests(for medications: [MedicationSchedule], calendar: Calendar) -> [UNNotificationRequest] {
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let upcomingDoses = medications.flatMap { medication in
            scheduledDoses(for: medication, from: today, now: now, calendar: calendar)
        }

        return upcomingDoses
            .sorted { $0.fireDate < $1.fireDate }
            .map { dose in
                let content = UNMutableNotificationContent()
                content.title = localizedAppString("Medicine Reminder")
                content.body = dose.bodyText
                content.sound = .default
                content.userInfo = [
                    "kind": "medicineReminder",
                    "medicationChecklistID": dose.checklistID
                ]

                let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: dose.fireDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                return UNNotificationRequest(identifier: dose.identifier, content: content, trigger: trigger)
            }
    }

    private static func scheduledDoses(
        for medication: MedicationSchedule,
        from today: Date,
        now: Date,
        calendar: Calendar
    ) -> [ScheduledMedicationDose] {
        let startDay = calendar.startOfDay(for: medication.startDate)
        let endDay = medicationEndDay(for: medication, calendar: calendar)
        var doses: [ScheduledMedicationDose] = []

        for offset in 0..<horizonDays {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today),
                  day >= startDay else {
                continue
            }

            if let endDay, day > endDay {
                continue
            }

            let dayTimes = dueTimes(for: medication, on: day, startDay: startDay, calendar: calendar)

            for dayTime in dayTimes {
                let doseDay = medication.mode == .weekly ? MedicationWeekday.from(date: day, calendar: calendar) : nil
                let storedTime = medication.clockTime(for: doseDay, time: dayTime)
                let minutes = MedicationTimeFormatting.minutes(for: storedTime)
                guard let fireDate = calendar.date(
                    bySettingHour: minutes / 60,
                    minute: minutes % 60,
                    second: 0,
                    of: day
                ), fireDate > now else {
                    continue
                }

                doses.append(
                    ScheduledMedicationDose(
                        identifier: "\(identifierPrefix)\(medication.id.uuidString).\(dateKey(day, calendar: calendar)).\(medication.doseKey(day: doseDay, time: dayTime))",
                        fireDate: fireDate,
                        bodyText: reminderBody(for: medication, day: doseDay, time: dayTime),
                        checklistID: MedicationChecklistIdentifier.id(for: medication, day: doseDay, time: dayTime)
                    )
                )
            }
        }

        return doses
    }

    private static func dueTimes(
        for medication: MedicationSchedule,
        on day: Date,
        startDay: Date,
        calendar: Calendar
    ) -> [MedicationDayTime] {
        switch medication.mode {
        case .daily:
            return medication.dailyTimes
        case .intervalDays:
            let daysSinceStart = calendar.dateComponents([.day], from: startDay, to: day).day ?? 0
            return daysSinceStart >= 0 && daysSinceStart % max(1, medication.intervalDays) == 0
                ? medication.dailyTimes
                : []
        case .weekly:
            guard let weekday = MedicationWeekday.from(date: day, calendar: calendar),
                  medication.weeklyDays.contains(weekday) else {
                return []
            }

            return medication.weeklyTimes
        }
    }

    private static func reminderBody(for medication: MedicationSchedule, day: MedicationWeekday?, time: MedicationDayTime) -> String {
        let name = medication.displayName.isEmpty ? "medicine" : medication.displayName
        let dose = medication.dose(for: day, time: time)
        return dose.isEmpty ? "Time to take \(name)." : "Time to take \(name) \(dose)."
    }

    private static func medicationEndDay(for medication: MedicationSchedule, calendar: Calendar) -> Date? {
        let duration = medication.duration.lowercased()
        guard duration.contains("day"),
              let numberText = duration.split(separator: " ").first,
              let days = Int(numberText) else {
            return nil
        }

        return calendar.date(byAdding: .day, value: max(0, days - 1), to: calendar.startOfDay(for: medication.startDate))
    }

    private static func dateKey(_ date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d%02d%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }
}

