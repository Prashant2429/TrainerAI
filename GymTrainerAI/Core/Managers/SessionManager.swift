import Foundation
import Combine
import SwiftData

class SessionManager: ObservableObject {
    @Published var session = WorkoutSession()
    @Published var conversationHistory: [[String: String]] = []
    @Published var lastFormError: FormRule? = nil
    @Published var repCount: Int = 0
    @Published var currentErrorJoints: Set<String> = []
    @Published var lastDebriefText: String = ""

    var modelContext: ModelContext?
    private var pendingSetEntries: [SetLogEntry] = []
    private var workoutStartTime = Date()
    private var gripSamplesDuringSet: [Float] = []
    @Published var lastGripTip: String = ""
    @Published var isListeningForVoice: Bool = false
    @Published var voiceTranscript: String = ""

    private var voiceListenCancellable: AnyCancellable?
    private var voiceTranscriptCancellable: AnyCancellable?

    // Services
    let voiceCoach    = VoiceCoachService()
    let aiService     = AIService()
    let poseService   = PoseDetectionService()
    let formAnalyzer  = FormAnalysisService()
    let handService   = HandDetectionService()
    let fingerCurl    = FingerCurlService()

    private var poseCancellable: AnyCancellable?
    private var curlCancellable: AnyCancellable?

    init() {
        poseService.onSessionReady = { [weak self] in
            guard let self else { return }
            self.handService.attach(to: self.poseService.captureSession)
            self.fingerCurl.attach(to: self.handService)
        }

        setupFormAnalyzer()
        subscribeToPose()
        subscribeToCurl()
        subscribeToVoice()

        voiceCoach.requestPermissions()
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

                if let curl = self?.fingerCurl.curlData {
                    self?.gripSamplesDuringSet.append(
                        (curl.indexPIP + curl.middlePIP) / 2.0
                    )
                }
            }
        }
    }

    private func subscribeToVoice() {
        voiceListenCancellable = voiceCoach.$isListening
            .receive(on: DispatchQueue.main)
            .sink { [weak self] val in
                self?.isListeningForVoice = val
            }

        voiceTranscriptCancellable = voiceCoach.$partialTranscript
            .receive(on: DispatchQueue.main)
            .sink { [weak self] val in
                self?.voiceTranscript = val
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

    // MARK: - Session Control

    func startSet(exercise: Exercise) {
        if pendingSetEntries.isEmpty {
            workoutStartTime = Date()
            NotificationService.shared.cancelTodayCheckIn()
        }

        session.startSet(exercise: exercise)

        repCount = 0
        gripSamplesDuringSet = []
        lastGripTip = ""
        lastFormError = nil
        currentErrorJoints = []

        formAnalyzer.setExercise(exercise)
        formAnalyzer.reset()

        poseService.start()

        // After set 1, lead with last set's top error as a reminder
        var cue = "Set \(session.currentSetNumber). \(exercise.phonePlacementInstruction)."
        if let lastError = pendingSetEntries.last?.errorsDetected.first {
            cue += " Watch your \(lastError) this set."
        }
        voiceCoach.speakDebrief(cue)
    }

    func endSet() {
        poseService.stop()

        let grip = gripSamplesDuringSet
        gripSamplesDuringSet = []

        // Capture per-rep timeline before startSet() resets it
        let capturedRepTimeline = session.repErrorTimeline

        session.endSet(gripTimeline: grip)

        if let log = session.sessionLog.last,
           let exercise = session.currentExercise {

            let avgGrip: Float? = grip.isEmpty
                ? nil
                : grip.reduce(0, +) / Float(grip.count)

            let entry = SetLogEntry(
                exercise: log.exercise,
                exerciseId: exercise.id,
                setNumber: log.setNumber,
                reps: log.reps,
                formScore: log.formScore,
                errorsDetected: log.errorsDetected,
                gripAvgAngle: avgGrip,
                gripTimeline: grip,
                timestamp: log.timestamp
            )

            pendingSetEntries.append(entry)
        }

        Task {
            async let debrief: Void = generateSetDebrief(repTimeline: capturedRepTimeline)
            async let gripTip: Void = generateGripTip(timeline: grip)
            _ = await (debrief, gripTip)
        }
    }

    func endWorkout() {
        defer { pendingSetEntries = [] }

        guard let ctx = modelContext,
              !pendingSetEntries.isEmpty else { return }

        let duration = Int(Date().timeIntervalSince(workoutStartTime))

        let record = WorkoutRecord(
            date: workoutStartTime,
            durationSeconds: duration,
            sets: pendingSetEntries
        )

        ctx.insert(record)

        do {
            try ctx.save()

            NotificationService.shared.scheduleCheckIn(
                after: record,
                nextPlanDay: nil
            )

        } catch {
            print("❌ WorkoutRecord save failed: \(error)")
        }
    }

    // MARK: - Claude Debrief

    private func generateSetDebrief(repTimeline: [[String]]) async {
        // Capture all session state before first await (main thread only)
        guard let exercise = session.currentExercise,
              let lastLog  = session.sessionLog.last else { return }

        let errors    = lastLog.errorsDetected
        let reps      = lastLog.reps
        let setNumber = lastLog.setNumber
        let formScore = Int(lastLog.formScore * 100)
        let history   = Array(conversationHistory.suffix(6))

        // User profile context
        var profileText = ""
        if let data = UserDefaults.standard.data(forKey: "userProfile"),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            profileText = "\(profile.name), \(profile.age)yo \(profile.gender.rawValue), \(profile.fitnessLevel.rawValue)."
        }

        // New vs repeated errors vs last set
        var newErrors: [String] = []
        var repeatedErrors: [String] = []
        if session.sessionLog.count >= 2 {
            let prevErrors = session.sessionLog[session.sessionLog.count - 2].errorsDetected
            for e in errors {
                if prevErrors.contains(e) { repeatedErrors.append(e) }
                else { newErrors.append(e) }
            }
        } else {
            newErrors = errors
        }

        // Per-rep breakdown (only reps that had errors)
        let perRepText: String = {
            let breakdown = repTimeline.enumerated()
                .filter { !$0.element.isEmpty }
                .map { "rep \($0.offset + 1): \($0.element.joined(separator: ", "))" }
                .joined(separator: "; ")
            return breakdown.isEmpty ? "" : " Per-rep: \(breakdown)."
        }()

        let prompt: String
        if errors.isEmpty {
            let prevScore = session.sessionLog.count >= 2
                ? Int(session.sessionLog[session.sessionLog.count - 2].formScore * 100)
                : nil
            let trend = prevScore.map { formScore >= $0 ? "up from \($0)%" : "down from \($0)%" } ?? "first set"
            prompt = "\(profileText.isEmpty ? "" : "Athlete: \(profileText) ")Set \(setNumber) of \(exercise.name). \(reps) reps, form \(formScore)% (\(trend)). Clean set. Give one energetic 1-sentence trainer response."
        } else {
            let newPart    = newErrors.isEmpty     ? "" : " New this set: \(newErrors.joined(separator: ", "))."
            let repeatPart = repeatedErrors.isEmpty ? "" : " Repeated: \(repeatedErrors.joined(separator: ", "))."
            prompt = "\(profileText.isEmpty ? "" : "Athlete: \(profileText) ")Set \(setNumber) of \(exercise.name). \(reps) reps, form \(formScore)%.\(newPart)\(repeatPart)\(perRepText) Give one specific actionable cue for the next set."
        }

        let response = await aiService.ask(userMessage: prompt, conversationHistory: history)

        conversationHistory.append(["role": "user",      "content": prompt])
        conversationHistory.append(["role": "assistant", "content": response])

        await MainActor.run {
            lastDebriefText = response
            voiceCoach.speakDebrief(response)
        }
    }

    // MARK: - Grip Tip

    private func generateGripTip(timeline: [Float]) async {
        guard timeline.count >= 2 else { return }

        let angles = timeline
            .map { "\(Int($0))" }
            .joined(separator: ", ")

        let prompt =
        "Grip angles per rep in degrees: [\(angles)]. Give one specific coaching tip in under 12 words."

        let response = await aiService.ask(
            userMessage: prompt,
            conversationHistory: []
        )

        await MainActor.run {
            lastGripTip = response
        }
    }

    // MARK: - Coach Chat

    func chatWithCoach(
        message: String,
        chatHistory: [[String: String]],
        workoutContext: String
    ) async -> String {

        var profileText = ""

        if let data = UserDefaults.standard.data(forKey: "userProfile"),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {

            profileText =
            "Athlete: \(profile.name), \(profile.age)yo \(profile.gender.rawValue), \(profile.fitnessLevel.rawValue) level, \(profile.hasEquipment.rawValue), \(profile.availableDaysPerWeek) days/week."
        }

        let system = """
        You are a personal AI trainer.
        Be specific and reference the user's actual workout data.

        \(profileText)

        Recent workouts:
        \(workoutContext.isEmpty ? "No workouts logged yet." : workoutContext)

        Keep responses under 3 sentences.
        """

        return await aiService.askCoach(
            userMessage: message,
            conversationHistory: chatHistory,
            system: system
        )
    }

    // MARK: - Plan Generation

    func generatePlan(profile: UserProfile) async -> WorkoutPlanDTO? {
        await aiService.generatePlan(profile: profile)
    }

    // MARK: - Voice Input

    func startVoiceInput() {
        voiceCoach.startListening { [weak self] text in
            self?.handleUserSpeech(text)
        }
    }

    func stopVoiceInput() {
        voiceCoach.stopListening()
    }

    // MARK: - User Speech

    func handleUserSpeech(_ text: String) {
        Task {
            let response = await aiService.ask(
                userMessage: text,
                conversationHistory: conversationHistory
            )

            conversationHistory.append([
                "role": "user",
                "content": text
            ])

            conversationHistory.append([
                "role": "assistant",
                "content": response
            ])

            await MainActor.run {
                voiceCoach.speakDebrief(response)
            }
        }
    }

    // MARK: - Logout / Reset

    @MainActor
    func resetForLogout() {

        // Stop services
        poseService.stop()
        voiceCoach.stopListening()

        // Reset memory state
        session = WorkoutSession()
        conversationHistory = []
        lastFormError = nil
        repCount = 0
        currentErrorJoints = []
        lastDebriefText = ""
        pendingSetEntries = []
        gripSamplesDuringSet = []
        lastGripTip = ""
        isListeningForVoice = false
        voiceTranscript = ""

        // Cancel notifications
        NotificationService.shared.cancelTodayCheckIn()

        // Clear UserDefaults
        let defaults = UserDefaults.standard

        defaults.removeObject(forKey: "coachChatHistory")
        defaults.removeObject(forKey: "userProfile")
        defaults.removeObject(forKey: "userName")

        defaults.set(false, forKey: "hasCompletedOnboarding")

        // Clear SwiftData
        wipeAllSwiftData()
    }

    // MARK: - SwiftData Wipe

    private func wipeAllSwiftData() {
        guard let ctx = modelContext else { return }

        do {

            if let records = try? ctx.fetch(
                FetchDescriptor<WorkoutRecord>()
            ) {
                for record in records {
                    ctx.delete(record)
                }
            }

            if let plans = try? ctx.fetch(
                FetchDescriptor<WorkoutPlan>()
            ) {
                for plan in plans {
                    ctx.delete(plan)
                }
            }

            if let entries = try? ctx.fetch(
                FetchDescriptor<SetLogEntry>()
            ) {
                for entry in entries {
                    ctx.delete(entry)
                }
            }

            try ctx.save()

            print("✅ Cleared all SwiftData")

        } catch {
            print("❌ Wipe SwiftData failed: \(error)")
        }
    }
}
