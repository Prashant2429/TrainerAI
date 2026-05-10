import Foundation

class WorkoutSession: ObservableObject {
    @Published var currentExercise: Exercise?
    @Published var currentSetNumber: Int = 1
    @Published var repCount: Int = 0
    @Published var isSetActive: Bool = false
    @Published var formErrors: [String] = []
    @Published var sessionLog: [SetLog] = []

    // Per-rep error accumulator — cleared each rep, snapshotted into repErrorTimeline
    var currentRepErrors: [String] = []
    var repErrorTimeline: [[String]] = []

    struct SetLog: Identifiable {
        let id = UUID()
        let exercise: String
        let setNumber: Int
        let reps: Int
        let formScore: Double
        let errorsDetected: [String]
        let gripTimeline: [Float]
        let repErrorTimeline: [[String]]
        let timestamp: Date
    }

    func startSet(exercise: Exercise) {
        currentExercise = exercise
        repCount = 0
        formErrors = []
        currentRepErrors = []
        repErrorTimeline = []
        isSetActive = true
    }

    func endSet(gripTimeline: [Float] = []) {
        guard let exercise = currentExercise else { return }
        let log = SetLog(
            exercise: exercise.name,
            setNumber: currentSetNumber,
            reps: repCount,
            formScore: formScore(),
            errorsDetected: formErrors,
            gripTimeline: gripTimeline,
            repErrorTimeline: repErrorTimeline,
            timestamp: Date()
        )
        sessionLog.append(log)
        currentSetNumber += 1
        isSetActive = false
    }

    func logRep() {
        repErrorTimeline.append(currentRepErrors)
        currentRepErrors = []
        repCount += 1
    }

    func logFormError(_ error: String) {
        if !formErrors.contains(error) {
            formErrors.append(error)
        }
        currentRepErrors.append(error)
    }

    private func formScore() -> Double {
        guard repCount > 0 else { return 1.0 }
        let errorRate = Double(formErrors.count) / Double(repCount)
        return max(0, 1.0 - errorRate)
    }
}
