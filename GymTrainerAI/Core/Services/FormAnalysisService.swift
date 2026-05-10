import Foundation
import CoreGraphics

// MARK: - Rep state machine

private enum RepState { case idle, descending, bottom }

class FormAnalysisService: ObservableObject {

    // Callbacks
    var onFormError: ((FormRule) -> Void)?
    var onRepCompleted: (() -> Void)?

    var latestCurlData: FingerCurlData?

    private var currentExercise: Exercise?
    private var errorCooldowns: [String: Date] = [:]
    private let errorCooldown: TimeInterval = 3.0

    // History for velocity & angle-change checks
    private var poseHistory: [PoseData] = []
    private let historySize = 12

    // Rep counting state
    private var repState: RepState = .idle
    private var repMinAngle: Double = 180.0

    // MARK: - Setup

    func setExercise(_ exercise: Exercise) {
        currentExercise = exercise
        poseHistory.removeAll()
        repState = .idle
        repMinAngle = 180.0
        errorCooldowns.removeAll()
    }

    func reset() {
        poseHistory.removeAll()
        repState = .idle
        repMinAngle = 180.0
        errorCooldowns.removeAll()
    }

    // MARK: - Main analysis entry point

    func analyze(pose: PoseData) {
        poseHistory.append(pose)
        if poseHistory.count > historySize { poseHistory.removeFirst() }

        guard let exercise = currentExercise else { return }

        for rule in exercise.formRules {
            evaluateRule(rule, pose: pose)
        }

        trackRep(pose: pose, exerciseId: exercise.id)
    }

    // MARK: - Rule evaluation dispatcher

    private func evaluateRule(_ rule: FormRule, pose: PoseData) {
        guard canFire(ruleId: rule.id) else { return }

        let triggered: Bool

        switch rule.id {
        case "squat_valgus", "lunge_knee":
            triggered = checkKneeCaving(pose: pose)
        case "squat_depth":
            triggered = checkSquatDepth(pose: pose)
        case "curl_swing", "row_momentum":
            triggered = checkTorsoVelocity(threshold: 0.012)
        case "curl_elbow", "pushdown_elbow":
            triggered = checkElbowDrift(pose: pose, threshold: 0.045)
        case "lateral_shrug":
            triggered = checkShoulderShrug(pose: pose)
        case "lateral_lean":
            triggered = checkTorsoLateralTilt(pose: pose, maxDegrees: 8.0)
        case "deadlift_spine":
            triggered = checkSpineRounding(pose: pose, maxDeviation: 20.0)
        case "bench_elbow_flare":
            triggered = checkElbowFlare(pose: pose, maxDegrees: 75.0)
        case "ohp_back_arch":
            triggered = checkLumbarArch(pose: pose, maxAngle: 155.0)
        case "cable_row_rock":
            triggered = checkTorsoAngleChange(threshold: 15.0)
        case "deadlift_grip", "row_grip":
            triggered = checkGripOpening()
        default:
            triggered = false
        }

        if triggered {
            setCooldown(ruleId: rule.id)
            onFormError?(rule)
        }
    }

    // MARK: - Individual form checks

    /// Knees caving inward — knee width significantly less than ankle width
    private func checkKneeCaving(pose: PoseData) -> Bool {
        // Prefer 3D x-positions (works from any camera angle)
        if let lk3 = pose.joints3D?["leftKnee"],  let la3 = pose.joints3D?["leftAnkle"],
           let rk3 = pose.joints3D?["rightKnee"], let ra3 = pose.joints3D?["rightAnkle"] {
            let kneeSpan  = abs(rk3.x - lk3.x)
            let ankleSpan = abs(ra3.x - la3.x)
            guard ankleSpan > 0.15 else { return false }
            return kneeSpan < ankleSpan * 0.78
        }
        guard let lk = pose.joints["leftKnee"],  let la = pose.joints["leftAnkle"],
              let rk = pose.joints["rightKnee"], let ra = pose.joints["rightAnkle"] else { return false }
        let kneeSpan  = abs(rk.x - lk.x)
        let ankleSpan = abs(ra.x - la.x)
        guard ankleSpan > 0.05 else { return false }
        return kneeSpan < ankleSpan * 0.78
    }

    /// Hip not reaching knee level at bottom of squat
    private func checkSquatDepth(pose: PoseData) -> Bool {
        // Prefer 3D y-axis (true vertical, camera-angle independent)
        if let h3 = pose.joints3D?["leftHip"] ?? pose.joints3D?["rightHip"],
           let k3 = pose.joints3D?["leftKnee"] ?? pose.joints3D?["rightKnee"] {
            // Only check when hip has descended within 35cm of knee (person is squatting)
            guard h3.y - k3.y < 0.35 else { return false }
            return h3.y > k3.y + 0.05
        }
        guard let hip  = pose.joints["leftHip"] ?? pose.joints["rightHip"],
              let knee = pose.joints["leftKnee"] ?? pose.joints["rightKnee"] else { return false }
        guard knee.y > hip.y + 0.04 else { return false }
        return hip.y < knee.y - 0.01
    }

    /// Torso moving too fast between frames (momentum / swinging)
    private func checkTorsoVelocity(threshold: Double) -> Bool {
        guard poseHistory.count >= 4 else { return false }
        var points: [CGPoint] = []
        for pose in poseHistory.suffix(4) {
            if let lh = pose.joints["leftHip"], let rh = pose.joints["rightHip"] {
                points.append(CGPoint(x: (lh.x + rh.x) / 2, y: (lh.y + rh.y) / 2))
            }
        }
        guard points.count >= 2 else { return false }
        var maxDelta = 0.0
        for i in 1..<points.count {
            let dx = Double(points[i].x - points[i-1].x)
            let dy = Double(points[i].y - points[i-1].y)
            maxDelta = max(maxDelta, sqrt(dx*dx + dy*dy))
        }
        return maxDelta > threshold
    }

    /// Elbow drifting forward / away from body axis
    private func checkElbowDrift(pose: PoseData, threshold: CGFloat) -> Bool {
        func singleSideDrift(elbow: String, shoulder: String) -> Bool {
            guard let e = pose.joints[elbow], let s = pose.joints[shoulder] else { return false }
            return abs(e.x - s.x) > threshold
        }
        return singleSideDrift(elbow: "leftElbow",  shoulder: "leftShoulder") ||
               singleSideDrift(elbow: "rightElbow", shoulder: "rightShoulder")
    }

    /// Shoulders rising toward ears (traps compensating on lateral raise)
    private func checkShoulderShrug(pose: PoseData) -> Bool {
        func shrug(shoulder: String, ear: String) -> Bool {
            guard let s = pose.joints[shoulder], let e = pose.joints[ear] else { return false }
            return abs(s.y - e.y) < 0.07  // Shoulder very close to ear = shrug
        }
        return shrug(shoulder: "leftShoulder", ear: "leftEar") ||
               shrug(shoulder: "rightShoulder", ear: "rightEar")
    }

    /// Torso leaning laterally (shoulder line tilted from horizontal)
    private func checkTorsoLateralTilt(pose: PoseData, maxDegrees: Double) -> Bool {
        guard let ls = pose.joints["leftShoulder"], let rs = pose.joints["rightShoulder"] else { return false }
        let dx = Double(rs.x - ls.x)
        let dy = Double(rs.y - ls.y)
        guard abs(dx) > 0.02 else { return false }
        let angleDeg = abs(atan2(dy, dx) * 180.0 / .pi)
        return angleDeg > maxDegrees
    }

    /// Spine rounding — shoulder-hip line tilts too far from vertical
    private func checkSpineRounding(pose: PoseData, maxDeviation: Double) -> Bool {
        guard let shoulder = pose.joints["leftShoulder"] ?? pose.joints["rightShoulder"],
              let hip      = pose.joints["leftHip"]      ?? pose.joints["rightHip"] else { return false }
        // Vector from hip → shoulder; deviation from vertical
        let dx = Double(shoulder.x - hip.x)
        let dy = Double(hip.y - shoulder.y)  // Positive = shoulder above hip (correct)
        guard dy > 0 else { return false }    // Person upright (not lying down)
        let deviationDeg = abs(atan2(dx, dy) * 180.0 / .pi)
        return deviationDeg > maxDeviation
    }

    /// Elbow flare on bench — angle between arm and torso exceeds max
    private func checkElbowFlare(pose: PoseData, maxDegrees: Double) -> Bool {
        guard let ls = pose.joints["leftShoulder"],  let le = pose.joints["leftElbow"],
              let rs = pose.joints["rightShoulder"], let re = pose.joints["rightElbow"] else { return false }

        func flareAngle(shoulder: CGPoint, elbow: CGPoint, opposite: CGPoint) -> Double {
            // Angle between arm vector and torso vector (shoulder → opposite shoulder)
            let armVec    = CGPoint(x: elbow.x - shoulder.x,   y: elbow.y - shoulder.y)
            let torsoVec  = CGPoint(x: opposite.x - shoulder.x, y: opposite.y - shoulder.y)
            let dot       = armVec.x * torsoVec.x + armVec.y * torsoVec.y
            let mag1      = sqrt(armVec.x * armVec.x + armVec.y * armVec.y)
            let mag2      = sqrt(torsoVec.x * torsoVec.x + torsoVec.y * torsoVec.y)
            guard mag1 > 0.01, mag2 > 0.01 else { return 0 }
            return acos(max(-1, min(1, Double(dot / (mag1 * mag2))))) * 180.0 / .pi
        }

        let lFlare = flareAngle(shoulder: ls, elbow: le, opposite: rs)
        let rFlare = flareAngle(shoulder: rs, elbow: re, opposite: ls)
        return lFlare > maxDegrees || rFlare > maxDegrees
    }

    /// Lumbar arch on OHP — hip angle too obtuse = leaning back excessively
    private func checkLumbarArch(pose: PoseData, maxAngle: Double) -> Bool {
        guard let shoulder = pose.joints["leftShoulder"] ?? pose.joints["rightShoulder"],
              let hip      = pose.joints["leftHip"]      ?? pose.joints["rightHip"],
              let knee     = pose.joints["leftKnee"]     ?? pose.joints["rightKnee"] else { return false }
        let angle = calculateAngle(a: shoulder, vertex: hip, c: knee)
        return angle > maxAngle
    }

    /// Grip opening — fingers not sufficiently curled (PIP angle too obtuse)
    private func checkGripOpening() -> Bool {
        guard let curl = latestCurlData else { return false }
        let avgPIP = (Float(curl.indexPIP) + Float(curl.middlePIP)) / 2.0
        return avgPIP > 145.0
    }

    /// Cable row torso rocking — torso angle changed significantly within this rep
    private func checkTorsoAngleChange(threshold: Double) -> Bool {
        guard poseHistory.count >= 6 else { return false }

        func torsoAngle(from pose: PoseData) -> Double? {
            guard let s = pose.joints["leftShoulder"] ?? pose.joints["rightShoulder"],
                  let h = pose.joints["leftHip"]      ?? pose.joints["rightHip"] else { return nil }
            let dx = Double(s.x - h.x); let dy = Double(h.y - s.y)
            return atan2(dx, dy) * 180.0 / .pi
        }

        guard let current = torsoAngle(from: poseHistory.last!),
              let past    = torsoAngle(from: poseHistory[poseHistory.count - 6]) else { return false }
        return abs(current - past) > threshold
    }

    // MARK: - Rep counting

    private func trackRep(pose: PoseData, exerciseId: String) {
        let config = repConfig(for: exerciseId)
        // Prefer higher-confidence side; fall back to opposite if primary is missing
        guard let a = bestPoint(config.pointA, pose: pose),
              let v = bestPoint(config.vertex, pose: pose),
              let c = bestPoint(config.pointB, pose: pose) else { return }

        let angle = calculateAngle(a: a, vertex: v, c: c)

        switch repState {
        case .idle:
            if angle < config.bottomThreshold {
                repState = .descending
                repMinAngle = angle
            }
        case .descending:
            repMinAngle = min(repMinAngle, angle)
            if angle < config.deepThreshold {
                repState = .bottom
            } else if angle > config.topThreshold {
                // Didn't reach bottom - reset
                repState = .idle
            }
        case .bottom:
            if angle > config.topThreshold && repMinAngle < config.deepThreshold {
                repState = .idle
                repMinAngle = 180.0
                onRepCompleted?()
            }
        }
    }

    // MARK: - Rep configs per exercise

    private struct RepConfig {
        let vertex: String; let pointA: String; let pointB: String
        let bottomThreshold: Double  // Start of rep range
        let deepThreshold: Double    // Must reach this to count
        let topThreshold: Double     // Rep complete when angle returns here
    }

    private func repConfig(for exerciseId: String) -> RepConfig {
        switch exerciseId {
        case "squat", "lunge", "goblet_squat", "leg_press", "leg_extension", "leg_curl":
            return RepConfig(vertex: "leftKnee",  pointA: "leftHip",      pointB: "leftAnkle",  bottomThreshold: 130, deepThreshold: 100, topThreshold: 155)
        case "deadlift", "romanian_deadlift", "hip_thrust":
            return RepConfig(vertex: "leftHip",   pointA: "leftShoulder", pointB: "leftKnee",   bottomThreshold: 130, deepThreshold: 90,  topThreshold: 155)
        case "bench_press", "ohp", "incline_press", "pushup", "pullup", "tricep_dip", "skull_crusher", "arnold_press":
            return RepConfig(vertex: "leftElbow", pointA: "leftShoulder", pointB: "leftWrist",  bottomThreshold: 130, deepThreshold: 80,  topThreshold: 155)
        default:
            return RepConfig(vertex: "leftElbow", pointA: "leftShoulder", pointB: "leftWrist",  bottomThreshold: 120, deepThreshold: 70,  topThreshold: 145)
        }
    }

    // MARK: - Bilateral joint helpers

    private func bestPoint(_ joint: String, pose: PoseData) -> CGPoint? {
        let alt = flipSide(joint)
        let confPrimary = pose.confidence[joint] ?? 0
        let confAlt     = pose.confidence[alt]   ?? 0
        if confPrimary >= confAlt {
            return pose.joints[joint] ?? pose.joints[alt]
        } else {
            return pose.joints[alt]   ?? pose.joints[joint]
        }
    }

    private func flipSide(_ joint: String) -> String {
        if joint.hasPrefix("left")  { return "right" + joint.dropFirst(4) }
        if joint.hasPrefix("right") { return "left"  + joint.dropFirst(5) }
        return joint
    }

    // MARK: - Math helpers

    func calculateAngle(a: CGPoint, vertex: CGPoint, c: CGPoint) -> Double {
        let v1 = CGPoint(x: a.x - vertex.x, y: a.y - vertex.y)
        let v2 = CGPoint(x: c.x - vertex.x, y: c.y - vertex.y)
        let dot  = v1.x * v2.x + v1.y * v2.y
        let mag1 = sqrt(v1.x * v1.x + v1.y * v1.y)
        let mag2 = sqrt(v2.x * v2.x + v2.y * v2.y)
        guard mag1 > 0.001, mag2 > 0.001 else { return 180 }
        return acos(max(-1, min(1, Double(dot / (mag1 * mag2))))) * 180.0 / .pi
    }

    // MARK: - Cooldown helpers

    private func canFire(ruleId: String) -> Bool {
        guard let last = errorCooldowns[ruleId] else { return true }
        return Date().timeIntervalSince(last) >= errorCooldown
    }

    private func setCooldown(ruleId: String) {
        errorCooldowns[ruleId] = Date()
    }
}
