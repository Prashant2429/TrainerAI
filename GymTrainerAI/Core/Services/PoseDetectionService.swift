import AVFoundation
import Vision
import UIKit

// Joints stored as normalized points — (0,0) = top-left, (1,1) = bottom-right
// joints3D: camera-space positions in metres from VNDetectHumanBodyPose3DRequest (optional)
struct PoseData {
    let joints: [String: CGPoint]
    let confidence: [String: Float]
    var joints3D: [String: SIMD3<Float>]? = nil

    func point(_ name: String) -> CGPoint? { joints[name] }
}

// Maps Vision joint names → readable string keys used in FormRule.jointKeypoints
private let visionJointMap: [(VNHumanBodyPoseObservation.JointName, String)] = [
    (.nose, "nose"),
    (.leftEye, "leftEye"), (.rightEye, "rightEye"),
    (.leftEar, "leftEar"), (.rightEar, "rightEar"),
    (.neck, "neck"),
    (.leftShoulder, "leftShoulder"), (.rightShoulder, "rightShoulder"),
    (.leftElbow, "leftElbow"),       (.rightElbow, "rightElbow"),
    (.leftWrist, "leftWrist"),       (.rightWrist, "rightWrist"),
    (.root, "root"),
    (.leftHip, "leftHip"),   (.rightHip, "rightHip"),
    (.leftKnee, "leftKnee"), (.rightKnee, "rightKnee"),
    (.leftAnkle, "leftAnkle"), (.rightAnkle, "rightAnkle")
]

// 3D joint name → readable key mapping (iOS 17+)
private let visionJointMap3D: [(VNHumanBodyPose3DObservation.JointName, String)] = [
    (.root,          "root"),
    (.leftHip,       "leftHip"),    (.rightHip,      "rightHip"),
    (.leftKnee,      "leftKnee"),   (.rightKnee,     "rightKnee"),
    (.leftAnkle,     "leftAnkle"),  (.rightAnkle,    "rightAnkle"),
    (.leftShoulder,  "leftShoulder"), (.rightShoulder, "rightShoulder"),
    (.leftElbow,     "leftElbow"),  (.rightElbow,    "rightElbow"),
    (.leftWrist,     "leftWrist"),  (.rightWrist,    "rightWrist"),
]

class PoseDetectionService: NSObject, ObservableObject {
    @Published var currentPose: PoseData?
    @Published var isRunning = false
    @Published var cameraPermissionGranted = false
    @Published var cameraPosition: AVCaptureDevice.Position = .front

    var onSessionReady: (() -> Void)?

    let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let poseQueue = DispatchQueue(label: "com.gymtrainer.pose", qos: .userInteractive)
    private var frameCount = 0

    override init() {
        super.init()
        checkPermission()
    }

    // MARK: - Permissions

    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraPermissionGranted = true
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.cameraPermissionGranted = granted
                    if granted { self?.setupSession() }
                }
            }
        default:
            cameraPermissionGranted = false
        }
    }

    // MARK: - Session setup

    private func setupSession() {
        // Remove existing inputs before reconfiguring
        captureSession.beginConfiguration()
        captureSession.inputs.forEach { captureSession.removeInput($0) }
        captureSession.sessionPreset = .vga640x480  // Lower res = faster Vision processing

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition),
              let input = try? AVCaptureDeviceInput(device: camera),
              captureSession.canAddInput(input) else {
            captureSession.commitConfiguration()
            return
        }
        captureSession.addInput(input)

        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        ]
        videoOutput.setSampleBufferDelegate(self, queue: poseQueue)

        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        if let connection = videoOutput.connection(with: .video) {
            if connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90  // Portrait
            }
        }

        captureSession.commitConfiguration()
        DispatchQueue.main.async { self.onSessionReady?() }
    }

    // MARK: - Start / Stop

    func start() {
        guard cameraPermissionGranted, !captureSession.isRunning else { return }
        poseQueue.async {
            self.captureSession.startRunning()
            DispatchQueue.main.async { self.isRunning = true }
        }
    }

    func stop() {
        guard captureSession.isRunning else { return }
        poseQueue.async {
            self.captureSession.stopRunning()
            DispatchQueue.main.async {
                self.isRunning = false
                self.currentPose = nil
            }
        }
    }

    func switchCamera() {
        let wasRunning = captureSession.isRunning
        poseQueue.async {
            if wasRunning { self.captureSession.stopRunning() }
            DispatchQueue.main.async {
                self.cameraPosition = self.cameraPosition == .front ? .back : .front
                self.setupSession()
                if wasRunning { self.start() }
            }
        }
    }

    // MARK: - Vision processing

    private func runPoseDetection(on buffer: CVPixelBuffer) {
        frameCount += 1

        let request2D = VNDetectHumanBodyPoseRequest()
        let request3D = VNDetectHumanBodyPose3DRequest()
        let run3D = frameCount % 3 == 0  // 3D at ~10 fps to reduce CPU load

        var requests: [VNRequest] = [request2D]
        if run3D { requests.append(request3D) }

        let handler = VNImageRequestHandler(cvPixelBuffer: buffer, orientation: .up, options: [:])
        do { try handler.perform(requests) } catch { return }

        guard let observation = request2D.results?.first else {
            DispatchQueue.main.async { self.currentPose = nil }
            return
        }

        var joints: [String: CGPoint] = [:]
        var confidence: [String: Float] = [:]

        for (visionName, key) in visionJointMap {
            guard let point = try? observation.recognizedPoint(visionName),
                  point.confidence > 0.3 else { continue }
            let x = cameraPosition == .front ? 1.0 - point.location.x : point.location.x
            joints[key] = CGPoint(x: x, y: 1.0 - point.location.y)
            confidence[key] = point.confidence
        }

        var joints3D: [String: SIMD3<Float>]? = nil
        if run3D, let obs3D = request3D.results?.first {
            var result: [String: SIMD3<Float>] = [:]
            for (name, key) in visionJointMap3D {
                guard let pt = try? obs3D.recognizedPoint(name) else { continue }
                let t = pt.position.columns.3
                result[key] = SIMD3<Float>(t.x, t.y, t.z)
            }
            if !result.isEmpty { joints3D = result }
        }

        let pose = PoseData(joints: joints, confidence: confidence, joints3D: joints3D)
        DispatchQueue.main.async { self.currentPose = pose }
    }
}

extension PoseDetectionService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        runPoseDetection(on: pixelBuffer)
    }
}
