import XCTest
@testable import GymTrainerAI

final class WorkoutSessionTests: XCTestCase {

    // MARK: - Helpers

    private func makeExercise() -> Exercise {
        Exercise(
            id: "test-exercise",
            name: "Squat",
            musclesTargeted: ["quads", "glutes"],
            category: .compound,
            cameraAngle: .sideProfile,
            phonePlacementInstruction: "Place phone to the side",
            formRules: [],
            stepByStepCues: [],
            commonMistakes: []
        )
    }

    // MARK: - testFormScorePerfect

    /// 5 reps, 0 errors → formScore should be 1.0
    func testFormScorePerfect() {
        let session = WorkoutSession()
        let exercise = makeExercise()

        session.startSet(exercise: exercise)
        session.repCount = 5
        session.endSet()

        let log = try! XCTUnwrap(session.sessionLog.last)
        XCTAssertEqual(log.formScore, 1.0, accuracy: 0.001)
    }

    // MARK: - testFormScoreZeroReps

    /// 0 reps → formScore should be 1.0 (guard branch, no crash)
    func testFormScoreZeroReps() {
        let session = WorkoutSession()
        let exercise = makeExercise()

        session.startSet(exercise: exercise)
        // repCount stays 0
        session.endSet()

        let log = try! XCTUnwrap(session.sessionLog.last)
        XCTAssertEqual(log.formScore, 1.0, accuracy: 0.001)
    }

    // MARK: - testFormScoreWithErrors

    /// 4 reps, 2 distinct errors → formScore = 1 - (2/4) = 0.5
    func testFormScoreWithErrors() {
        let session = WorkoutSession()
        let exercise = makeExercise()

        session.startSet(exercise: exercise)
        session.repCount = 4
        session.logFormError("knees caving")
        session.logFormError("back rounding")
        session.endSet()

        let log = try! XCTUnwrap(session.sessionLog.last)
        XCTAssertEqual(log.formScore, 0.5, accuracy: 0.001)
    }

    // MARK: - testLogFormErrorDeduplicates

    /// Logging the same error string twice should only add one entry
    func testLogFormErrorDeduplicates() {
        let session = WorkoutSession()
        let exercise = makeExercise()

        session.startSet(exercise: exercise)
        session.logFormError("knees caving")
        session.logFormError("knees caving")

        XCTAssertEqual(session.formErrors.count, 1)
    }

    // MARK: - testEndSetIncrementsSetNumber

    /// endSet() should increment currentSetNumber from 1 to 2
    func testEndSetIncrementsSetNumber() {
        let session = WorkoutSession()
        let exercise = makeExercise()

        XCTAssertEqual(session.currentSetNumber, 1)
        session.startSet(exercise: exercise)
        session.endSet()
        XCTAssertEqual(session.currentSetNumber, 2)
    }

    // MARK: - testEndSetAppendsToSessionLog

    /// endSet() should add exactly one entry to sessionLog
    func testEndSetAppendsToSessionLog() {
        let session = WorkoutSession()
        let exercise = makeExercise()

        XCTAssertTrue(session.sessionLog.isEmpty)
        session.startSet(exercise: exercise)
        session.endSet()
        XCTAssertEqual(session.sessionLog.count, 1)
    }

    // MARK: - testStartSetResetsState

    /// After accumulating reps and errors, startSet() should reset repCount to 0 and formErrors to []
    func testStartSetResetsState() {
        let session = WorkoutSession()
        let exercise = makeExercise()

        session.startSet(exercise: exercise)
        session.repCount = 3
        session.logFormError("back rounding")
        session.logFormError("knees caving")

        // Sanity-check that state is dirty
        XCTAssertEqual(session.repCount, 3)
        XCTAssertEqual(session.formErrors.count, 2)

        // Starting a new set must reset both
        session.startSet(exercise: exercise)
        XCTAssertEqual(session.repCount, 0)
        XCTAssertTrue(session.formErrors.isEmpty)
    }
}
