import AVFoundation
import Vision

// All 21 Vision hand joint names mapped to stable string keys
private let visionHandJointMap: [(VNHumanHandPoseObservation.JointName, String)] = [
    (.wrist,     "wrist"),
    (.thumbCMC,  "thumbCMC"), (.thumbMP,  "thumbMP"), (.thumbIP,  "thumbIP"), (.thumbTip,  "thumbTip"),
    (.indexMCP,  "indexMCP"), (.indexPIP, "indexPIP"), (.indexDIP, "indexDIP"), (.indexTip, "indexTip"),
    (.middleMCP, "middleMCP"), (.middlePIP, "middlePIP"), (.middleDIP, "middleDIP"), (.middleTip, "middleTip"),
    (.ringMCP,   "ringMCP"), (.ringPIP, "ringPIP"), (.ringDIP, "ringDIP"), (.ringTip, "ringTip"),
    (.littleMCP, "littleMCP"), (.littlePIP, "littlePIP"), (.littleDIP, "littleDIP"), (.littleTip, "littleTip")
]

class HandDetectionService: NSObject, ObservableObject {
    @Published var currentHands: [HandData] = []

    private let handOutput = AVCaptureVideoDataOutput()
    private let handQueue  = DispatchQueue(label: "com.gymtrainer.hand", qos: .userInteractive)

    // Called once from SessionManager after PoseDetectionService has been created.
    // Adds a second video output to the shared capture session — no new camera needed.
    func attach(to session: AVCaptureSession) {
        session.beginConfiguration()

        handOutput.alwaysDiscardsLateVideoFrames = true
        handOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        ]
        handOutput.setSampleBufferDelegate(self, queue: handQueue)

        if session.canAddOutput(handOutput) {
            session.addOutput(handOutput)
        }

        // Match the portrait rotation PoseDetectionService sets on its own connection
        if let connection = handOutput.connection(with: .video),
           connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }

        session.commitConfiguration()
    }

    // MARK: - Vision

    private func runHandDetection(on buffer: CVPixelBuffer) {
        let request = VNDetectHumanHandPoseRequest()
        request.maximumHandCount = 2
        let handler = VNImageRequestHandler(cvPixelBuffer: buffer, orientation: .up, options: [:])

        do { try handler.perform([request]) } catch { return }

        let observations = request.results ?? []
        let hands = observations.compactMap { parseHand($0) }

        DispatchQueue.main.async { self.currentHands = hands }
    }

    private func parseHand(_ observation: VNHumanHandPoseObservation) -> HandData? {
        let chirality: HandData.Chirality
        switch observation.chirality {
        case .left:    chirality = .left
        case .right:   chirality = .right
        default:       chirality = .unknown
        }

        var joints: [String: CGPoint] = [:]
        var confidence: [String: Float] = [:]

        for (visionName, key) in visionHandJointMap {
            guard let point = try? observation.recognizedPoint(visionName),
                  point.confidence > 0.3 else { continue }
            // Same coordinate transform as PoseDetectionService:
            // Vision (0,0) = bottom-left → flip Y; front camera → mirror X
            joints[key]     = CGPoint(x: 1.0 - point.location.x, y: 1.0 - point.location.y)
            confidence[key] = point.confidence
        }

        guard !joints.isEmpty else { return nil }
        return HandData(chirality: chirality, joints: joints, confidence: confidence)
    }
}

extension HandDetectionService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        runHandDetection(on: pixelBuffer)
    }
}
