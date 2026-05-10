import Foundation
import UserNotifications
import SwiftData

final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    private let identifierPrefix = "gymtrainer.checkin."

    func requestPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func scheduleCheckIn(after record: WorkoutRecord, nextPlanDay: PlannedDay?) {
        let fireDate: Date
        if let planDay = nextPlanDay, let next = nextOccurrence(of: planDay.day) {
            fireDate = next
        } else {
            let cal = Calendar.current
            let base = cal.date(byAdding: .day, value: 2, to: Date()) ?? Date()
            fireDate = cal.date(bySettingHour: 9, minute: 0, second: 0, of: base) ?? base
        }

        let content = UNMutableNotificationContent()
        content.title = "Time to train"
        content.body = personalizedMessage(for: record)
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let identifier = identifierPrefix + ISO8601DateFormatter().string(from: fireDate).prefix(10)

        let request = UNNotificationRequest(identifier: String(identifier), content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("❌ Notification schedule failed: \(error)") }
        }
    }

    func cancelTodayCheckIn() {
        let today = String(ISO8601DateFormatter().string(from: Date()).prefix(10))
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifierPrefix + today])
    }

    // MARK: - Private

    private func personalizedMessage(for record: WorkoutRecord) -> String {
        let avgScore = record.sets.isEmpty ? 1.0 :
            record.sets.map { $0.formScore }.reduce(0, +) / Double(record.sets.count)
        let topSet = record.sets.max { $0.reps < $1.reps }

        if avgScore < 0.7 {
            return "Your form score was \(Int(avgScore * 100))% last session. Today is your chance to push it higher."
        } else if let set = topSet {
            return "You hit \(set.reps) reps of \(set.exercise) last session. Ready to build on it?"
        } else {
            return "Your trainer is ready. Let's get after it."
        }
    }

    private func nextOccurrence(of weekdayName: String) -> Date? {
        let map = ["Sunday": 1, "Monday": 2, "Tuesday": 3, "Wednesday": 4,
                   "Thursday": 5, "Friday": 6, "Saturday": 7]
        guard let target = map[weekdayName] else { return nil }
        let cal = Calendar.current
        let today = cal.component(.weekday, from: Date())
        var ahead = target - today
        if ahead <= 0 { ahead += 7 }
        guard let future = cal.date(byAdding: .day, value: ahead, to: Date()) else { return nil }
        return cal.date(bySettingHour: 9, minute: 0, second: 0, of: future)
    }
}
