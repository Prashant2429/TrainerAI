import Foundation
import Combine

class SessionManager: ObservableObject {
    @Published var session = WorkoutSession()
    @Published var conversationHistory: [[String: String]] = []
    @Published var lastFormError: FormRule? = nil
    @Published var repCount: Int = 0
    @Published var currentErrorJoints: Set<String> = []
    @Published var lastDebriefText: String = ""

    // Services
    let voiceCoach    = VoiceCoachService()
    let claudeService = ClaudeService()
    let poseService   = PoseDetectionService()
    let formAnalyzer  = FormAnalysisService()
    let handService   = HandDetectionService()
    let fingerCurl    = FingerCurlService()

    private var poseCancellable: AnyCancellable?
    private var curlCancellable: AnyCancellable?

    init() {
        handService.attach(to: poseService.captureSession)
        fingerCurl.attach(to: handService)
        setupFormAnalyzer()
        subscribeToPose()
        subscribeToCurl()
    }

    // MARK: - Setup

    private func setupFormAnalyzer() {
        formAnalyzer.onFormError = { [weak self] rule in
            DispatchQueue.main.async {
                self?.session.logFormError(rule.debriefCue)
                self?.lastFormError = rule
                self?.currentErrorJoints = Set(rule.jointKeypoints)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    self?.currentErrorJoints = []
                }
                if rule.severity == .critical {
                    self?.voiceCoach.speakMidRepCue(rule.midRepCue)
                }
            }
        }

        formAnalyzer.onRepCompleted = { [weak self] in
            DispatchQueue.main.async {
                self?.session.logRep()
                self?.repCount = self?.session.repCount ?? 0
            }
        }
    }

    private func subscribeToCurl() {
        curlCancellable = fingerCurl.$curlData
            .receive(on: DispatchQueue.global(qos: .userInteractive))
            .sink { [weak self] data in
                self?.formAnalyzer.latestCurlData = data
            }
    }

    private func subscribeToPose() {
        poseCancellable = poseService.$currentPose
            .compactMap { $0 }
            .receive(on: DispatchQueue.global(qos: .userInteractive))
            .sink { [weak self] pose in
                guard self?.session.isSetActive == true else { return }
                self?.formAnalyzer.analyze(pose: pose)
            }
    }

    // MARK: - Session control

    func startSet(exercise: Exercise) {
        session.startSet(exercise: exercise)
        repCount = 0
        lastFormError = nil
        currentErrorJoints = []
        formAnalyzer.setExercise(exercise)
        formAnalyzer.reset()
        poseService.start()
        voiceCoach.speakDebrief("Starting \(exercise.name). \(exercise.phonePlacementInstruction)")
    }

    func endSet() {
        poseService.stop()
        session.endSet()
        Task { await generateSetDebrief() }
    }

    // MARK: - Claude debrief

    private func generateSetDebrief() async {
        guard let exercise = session.currentExercise else { return }
        let errors = session.formErrors
        let reps   = session.repCount

        let prompt: String
        if errors.isEmpty {
            prompt = "User completed \(reps) reps of \(exercise.name) with perfect form. Give a short energetic 1-sentence encouragement."
        } else {
            let errorList = errors.prefix(3).joined(separator: "; ")
            prompt = "User completed \(reps) reps of \(exercise.name). Form issues: \(errorList). Give one specific actionable correction for the next set in one sentence."
        }

        let response = await claudeService.ask(
            userMessage: prompt,
            conversationHistory: conversationHistory
        )
        conversationHistory.append(["role": "user",      "content": prompt])
        conversationHistory.append(["role": "assistant", "content": response])
        await MainActor.run {
            lastDebriefText = response
            voiceCoach.speakDebrief(response)
        }
    }

    // MARK: - User voice input (Phase 3)

    func handleUserSpeech(_ text: String) {
        Task {
            let response = await claudeService.ask(
                userMessage: text,
                conversationHistory: conversationHistory
            )
            conversationHistory.append(["role": "user",      "content": text])
            conversationHistory.append(["role": "assistant", "content": response])
            await MainActor.run { voiceCoach.speakDebrief(response) }
        }
    }
}
