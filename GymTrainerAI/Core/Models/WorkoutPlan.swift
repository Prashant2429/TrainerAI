import SwiftData
import Foundation

@Model
final class WorkoutPlan {
    var createdAt: Date
    var coachNote: String
    @Relationship(deleteRule: .cascade) var weeklyDays: [PlannedDay]

    init(createdAt: Date, coachNote: String, weeklyDays: [PlannedDay]) {
        self.createdAt = createdAt
        self.coachNote = coachNote
        self.weeklyDays = weeklyDays
    }
}

@Model
final class PlannedDay {
    var day: String
    var focus: String
    @Relationship(deleteRule: .cascade) var exercises: [PlannedExercise]

    init(day: String, focus: String, exercises: [PlannedExercise]) {
        self.day = day
        self.focus = focus
        self.exercises = exercises
    }
}

@Model
final class PlannedExercise {
    var exerciseId: String
    var sets: Int
    var reps: String
    var rest: Int

    init(exerciseId: String, sets: Int, reps: String, rest: Int) {
        self.exerciseId = exerciseId
        self.sets = sets
        self.reps = reps
        self.rest = rest
    }
}

// DTO used for decoding the Claude API response before converting to @Model
struct WorkoutPlanDTO: Codable {
    struct DayDTO: Codable {
        struct ExerciseDTO: Codable {
            let exerciseId: String
            let sets: Int
            let reps: String
            let rest: Int
        }
        let day: String
        let focus: String
        let exercises: [ExerciseDTO]
    }
    let weeklyPlan: [DayDTO]
    let coachNote: String
}
