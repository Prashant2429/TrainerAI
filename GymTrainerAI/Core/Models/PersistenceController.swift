import SwiftData
import Foundation

@Model
final class SetLogEntry {
    var id: UUID
    var exercise: String
    var exerciseId: String
    var setNumber: Int
    var reps: Int
    var formScore: Double
    var errorsDetected: [String]
    var gripAvgAngle: Float?
    var gripTimeline: [Float]
    var timestamp: Date

    init(exercise: String, exerciseId: String, setNumber: Int, reps: Int,
         formScore: Double, errorsDetected: [String],
         gripAvgAngle: Float? = nil, gripTimeline: [Float] = [], timestamp: Date) {
        self.id = UUID()
        self.exercise = exercise
        self.exerciseId = exerciseId
        self.setNumber = setNumber
        self.reps = reps
        self.formScore = formScore
        self.errorsDetected = errorsDetected
        self.gripAvgAngle = gripAvgAngle
        self.gripTimeline = gripTimeline
        self.timestamp = timestamp
    }
}

@Model
final class WorkoutRecord {
    var id: UUID
    var date: Date
    var durationSeconds: Int
    @Relationship(deleteRule: .cascade) var sets: [SetLogEntry]

    init(date: Date, durationSeconds: Int, sets: [SetLogEntry]) {
        self.id = UUID()
        self.date = date
        self.durationSeconds = durationSeconds
        self.sets = sets
    }
}
