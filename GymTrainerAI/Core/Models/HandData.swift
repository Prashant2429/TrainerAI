import CoreGraphics

struct HandData {
    enum Chirality: String {
        case left, right, unknown
    }

    let chirality: Chirality
    let joints: [String: CGPoint]
    let confidence: [String: Float]

    func point(_ name: String) -> CGPoint? { joints[name] }
}
