import Foundation
import Combine

// Joint angles for the MCP→PIP→DIP chain of index and middle fingers.
// Angles are in degrees. 180° = fully extended; lower = more curled.
struct FingerCurlData {
    let indexPIP:  Float   // angle at PIP: MCP–PIP–DIP
    let indexDIP:  Float   // angle at DIP: PIP–DIP–Tip
    let middlePIP: Float
    let middleDIP: Float
}

// Per-finger data for all five fingers. Used by FingerTestView.
struct SingleFingerData {
    let detected: Bool
    let proximalAngle: Float  // PIP for fingers, MP for thumb (0 if !detected)
    let distalAngle:   Float  // DIP for fingers, IP for thumb  (0 if !detected)

    // 0 = fully extended, 1 = fully curled
    var curlPercent: Double {
        guard detected else { return 0 }
        let avg = Double((proximalAngle + distalAngle) / 2)
        return max(0, min(1, 1.0 - (avg - 60) / 120.0))
    }
}

struct AllFingerData {
    let thumb:  SingleFingerData
    let index:  SingleFingerData
    let middle: SingleFingerData
    let ring:   SingleFingerData
    let little: SingleFingerData

    var fingers: [SingleFingerData] { [thumb, index, middle, ring, little] }
    var detectedCount: Int { fingers.filter(\.detected).count }
}

class FingerCurlService: ObservableObject {
    @Published var curlData: FingerCurlData?
    @Published var allFingerData: AllFingerData?

    private var cancellable: AnyCancellable?

    func attach(to handService: HandDetectionService) {
        cancellable = handService.$currentHands
            .receive(on: DispatchQueue.global(qos: .userInteractive))
            .sink { [weak self] hands in
                guard let self else { return }
                let hand = hands.first
                let curl    = hand.flatMap { self.computeCurl(from: $0) }
                let allFing = hand.flatMap { self.computeAllFingers(from: $0) }
                DispatchQueue.main.async {
                    self.curlData      = curl
                    self.allFingerData = allFing
                }
            }
    }

    // MARK: - Grip (index + middle only — used by workout HUD)

    private func computeCurl(from hand: HandData) -> FingerCurlData? {
        guard
            let indexPIP  = jointAngle(hand: hand, proximal: "indexMCP",  mid: "indexPIP",  distal: "indexDIP"),
            let indexDIP  = jointAngle(hand: hand, proximal: "indexPIP",  mid: "indexDIP",  distal: "indexTip"),
            let middlePIP = jointAngle(hand: hand, proximal: "middleMCP", mid: "middlePIP", distal: "middleDIP"),
            let middleDIP = jointAngle(hand: hand, proximal: "middlePIP", mid: "middleDIP", distal: "middleTip")
        else { return nil }

        return FingerCurlData(
            indexPIP: indexPIP, indexDIP: indexDIP,
            middlePIP: middlePIP, middleDIP: middleDIP
        )
    }

    // MARK: - All five fingers

    private func computeAllFingers(from hand: HandData) -> AllFingerData {
        AllFingerData(
            thumb:  finger(hand: hand, p: "thumbCMC",  m: "thumbMP",   d: "thumbIP",   t: "thumbTip"),
            index:  finger(hand: hand, p: "indexMCP",  m: "indexPIP",  d: "indexDIP",  t: "indexTip"),
            middle: finger(hand: hand, p: "middleMCP", m: "middlePIP", d: "middleDIP", t: "middleTip"),
            ring:   finger(hand: hand, p: "ringMCP",   m: "ringPIP",   d: "ringDIP",   t: "ringTip"),
            little: finger(hand: hand, p: "littleMCP", m: "littlePIP", d: "littleDIP", t: "littleTip")
        )
    }

    private func finger(hand: HandData, p: String, m: String, d: String, t: String) -> SingleFingerData {
        guard let a1 = jointAngle(hand: hand, proximal: p, mid: m, distal: d),
              let a2 = jointAngle(hand: hand, proximal: m, mid: d, distal: t)
        else { return SingleFingerData(detected: false, proximalAngle: 0, distalAngle: 0) }
        return SingleFingerData(detected: true, proximalAngle: a1, distalAngle: a2)
    }

    // MARK: - Geometry

    // Returns the angle (degrees) at `mid`, formed by the vectors mid→proximal and mid→distal.
    private func jointAngle(hand: HandData, proximal: String, mid: String, distal: String) -> Float? {
        guard let pA = hand.point(proximal),
              let pM = hand.point(mid),
              let pD = hand.point(distal) else { return nil }

        let v1 = CGVector(dx: pA.x - pM.x, dy: pA.y - pM.y)
        let v2 = CGVector(dx: pD.x - pM.x, dy: pD.y - pM.y)
        let mag = sqrt(v1.dx * v1.dx + v1.dy * v1.dy) * sqrt(v2.dx * v2.dx + v2.dy * v2.dy)
        guard mag > 1e-6 else { return nil }

        let cosTheta = (v1.dx * v2.dx + v1.dy * v2.dy) / mag
        return Float(acos(max(-1, min(1, cosTheta))) * 180.0 / .pi)
    }
}
