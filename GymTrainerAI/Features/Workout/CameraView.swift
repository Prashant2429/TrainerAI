import SwiftUI
import AVFoundation

// MARK: - Camera preview layer (UIKit wrapper)

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> VideoPreviewUIView {
        let view = VideoPreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        // Mirror preview so it acts like a selfie mirror — natural for self-monitoring
        view.previewLayer.connection?.automaticallyAdjustsVideoMirroring = false
        view.previewLayer.connection?.isVideoMirrored = true
        return view
    }

    func updateUIView(_ uiView: VideoPreviewUIView, context: Context) {}

    class VideoPreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}

// MARK: - Skeleton overlay

private let skeletonConnections: [(String, String)] = [
    // Head
    ("nose", "neck"),
    // Torso
    ("neck", "leftShoulder"),  ("neck", "rightShoulder"),
    ("leftShoulder", "leftHip"), ("rightShoulder", "rightHip"),
    ("leftHip", "rightHip"),
    // Left arm
    ("leftShoulder", "leftElbow"),  ("leftElbow", "leftWrist"),
    // Right arm
    ("rightShoulder", "rightElbow"), ("rightElbow", "rightWrist"),
    // Left leg
    ("leftHip", "leftKnee"),   ("leftKnee", "leftAnkle"),
    // Right leg
    ("rightHip", "rightKnee"), ("rightKnee", "rightAnkle")
]

struct SkeletonOverlay: View {
    let pose: PoseData
    let errorJoints: Set<String>       // Joints involved in current errors — shown in red

    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                // Draw bones
                for (start, end) in skeletonConnections {
                    guard let a = pose.joints[start], let b = pose.joints[end] else { continue }
                    var path = Path()
                    path.move(to: a.scaled(to: size))
                    path.addLine(to: b.scaled(to: size))
                    let color: Color = (errorJoints.contains(start) || errorJoints.contains(end)) ? .red : .green
                    ctx.stroke(path, with: .color(color.opacity(0.85)), lineWidth: 2.5)
                }

                // Draw joints
                for (name, point) in pose.joints {
                    let center = point.scaled(to: size)
                    let dotRect = CGRect(x: center.x - 5, y: center.y - 5, width: 10, height: 10)
                    let color: Color = errorJoints.contains(name) ? .red : .yellow
                    ctx.fill(Path(ellipseIn: dotRect), with: .color(color))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Full camera + overlay view

struct CameraView: View {
    @ObservedObject var poseService: PoseDetectionService
    let errorJoints: Set<String>

    var body: some View {
        ZStack {
            if poseService.cameraPermissionGranted {
                CameraPreviewView(session: poseService.captureSession)

                if let pose = poseService.currentPose {
                    SkeletonOverlay(pose: pose, errorJoints: errorJoints)
                }

                // No person detected
                if poseService.isRunning && poseService.currentPose == nil {
                    VStack {
                        Spacer()
                        Label("Position yourself in frame", systemImage: "person.fill")
                            .font(.callout)
                            .padding(.horizontal, 16).padding(.vertical, 8)
                            .background(.black.opacity(0.5))
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                        Spacer().frame(height: 20)
                    }
                }
            } else {
                // Permission denied
                VStack(spacing: 12) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Camera access needed")
                        .font(.headline)
                    Text("Enable camera in Settings to use form detection.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Helper

extension CGPoint {
    func scaled(to size: CGSize) -> CGPoint {
        CGPoint(x: x * size.width, y: y * size.height)
    }
}
