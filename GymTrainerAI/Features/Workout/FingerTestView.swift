import SwiftUI
import AVFoundation
import Combine

// MARK: - Standalone camera + hand session for the test tab

final class FingerTestSession: ObservableObject {
    @Published var hands: [HandData] = []
    @Published var allFingerData: AllFingerData? = nil
    @Published var permissionGranted = false

    let captureSession = AVCaptureSession()
    private let handService  = HandDetectionService()
    private let fingerCurl   = FingerCurlService()
    private var cancellables = Set<AnyCancellable>()
    private var configured   = false

    func start() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted { DispatchQueue.main.async { self?.start() } }
            }
            return
        }
        guard status == .authorized else { return }
        permissionGranted = true

        if !configured {
            setupCamera()
            handService.attach(to: captureSession)
            fingerCurl.attach(to: handService)

            handService.$currentHands
                .receive(on: DispatchQueue.main)
                .sink { [weak self] h in self?.hands = h }
                .store(in: &cancellables)

            fingerCurl.$allFingerData
                .receive(on: DispatchQueue.main)
                .sink { [weak self] d in self?.allFingerData = d }
                .store(in: &cancellables)

            configured = true
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    func stop() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.stopRunning()
        }
    }

    private func setupCamera() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .vga640x480

        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
           let input  = try? AVCaptureDeviceInput(device: device),
           captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        captureSession.commitConfiguration()
    }
}

// MARK: - Hand skeleton overlay (all 21 joints + per-finger colored bones)

private let handBones: [(String, String)] = [
    ("wrist","thumbCMC"), ("wrist","indexMCP"), ("wrist","middleMCP"),
    ("wrist","ringMCP"),  ("wrist","littleMCP"),
    ("indexMCP","middleMCP"), ("middleMCP","ringMCP"), ("ringMCP","littleMCP"),
    ("thumbCMC","thumbMP"),   ("thumbMP","thumbIP"),   ("thumbIP","thumbTip"),
    ("indexMCP","indexPIP"),  ("indexPIP","indexDIP"), ("indexDIP","indexTip"),
    ("middleMCP","middlePIP"),("middlePIP","middleDIP"),("middleDIP","middleTip"),
    ("ringMCP","ringPIP"),    ("ringPIP","ringDIP"),   ("ringDIP","ringTip"),
    ("littleMCP","littlePIP"),("littlePIP","littleDIP"),("littleDIP","littleTip"),
]

private func boneColor(for joint: String) -> Color {
    if joint.hasPrefix("thumb")  { return .orange }
    if joint.hasPrefix("index")  { return Color(red: 0.78, green: 1.00, blue: 0.18) } // DS.lime
    if joint.hasPrefix("middle") { return .cyan }
    if joint.hasPrefix("ring")   { return .purple }
    if joint.hasPrefix("little") { return .pink }
    return .white
}

struct HandSkeletonOverlay: View {
    let hands: [HandData]

    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                for hand in hands {
                    // Bones
                    for (start, end) in handBones {
                        guard let a = hand.joints[start], let b = hand.joints[end] else { continue }
                        var path = Path()
                        path.move(to: a.scaled(to: size))
                        path.addLine(to: b.scaled(to: size))
                        let col = boneColor(for: end)
                        ctx.stroke(path, with: .color(col.opacity(0.85)), lineWidth: 2)
                    }
                    // Joints
                    for (name, pt) in hand.joints {
                        let conf = Double(hand.confidence[name] ?? 0)
                        let center = pt.scaled(to: size)
                        let r: CGFloat = 4
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r*2, height: r*2)),
                            with: .color(.white.opacity(0.4 + conf * 0.6))
                        )
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Per-finger column card

private let fingerLabels = ["Thumb", "Index", "Middle", "Ring", "Little"]
private let fingerColors: [Color] = [.orange, Color(red:0.78,green:1,blue:0.18), .cyan, .purple, .pink]

struct FingerColumn: View {
    let label: String
    let color: Color
    let data: SingleFingerData

    var body: some View {
        VStack(spacing: 6) {
            Text(label.prefix(1))
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(data.detected ? color : Color.white.opacity(0.3))

            // Curl bar
            GeometryReader { g in
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.08))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(data.detected ? color : Color.clear)
                        .frame(height: g.size.height * data.curlPercent)
                }
            }

            // Angle readout
            VStack(spacing: 1) {
                angleText(data.proximalAngle)
                angleText(data.distalAngle)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func angleText(_ angle: Float) -> some View {
        Text(data.detected ? "\(Int(angle))°" : "—")
            .font(.system(size: 9, weight: .medium).monospacedDigit())
            .foregroundStyle(data.detected ? Color.white.opacity(0.7) : Color.white.opacity(0.25))
    }
}

// MARK: - Main test view

struct FingerTestView: View {
    @StateObject private var session = FingerTestSession()

    private var detectedJointCount: Int {
        session.hands.reduce(0) { $0 + $1.joints.count }
    }

    private var chiralityLabel: String {
        let labels = session.hands.map { h -> String in
            switch h.chirality {
            case .left:  return "L"
            case .right: return "R"
            default:     return "?"
            }
        }
        return labels.isEmpty ? "No hand" : labels.joined(separator: " + ")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DS.bg.ignoresSafeArea()

                if !session.permissionGranted {
                    permissionDeniedView
                } else {
                    VStack(spacing: 0) {
                        cameraSection
                        statusBar
                        fingerPanel
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                    }
                }
            }
            .navigationTitle("Finger Detection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .onAppear { session.start() }
        .onDisappear { session.stop() }
    }

    // MARK: - Camera + skeleton

    private var cameraSection: some View {
        ZStack {
            CameraPreviewView(session: session.captureSession)
                .aspectRatio(3/4, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous))
                .padding(.horizontal, 16)
                .padding(.top, 12)

            HandSkeletonOverlay(hands: session.hands)
                .padding(.horizontal, 16)
                .padding(.top, 12)

            if session.hands.isEmpty {
                VStack {
                    Spacer()
                    Label("Show your hand to the camera", systemImage: "hand.raised.fill")
                        .font(.callout.weight(.medium))
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(.black.opacity(0.6))
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                        .padding(.bottom, 28)
                }
            }
        }
    }

    // MARK: - Status bar

    private var statusBar: some View {
        HStack(spacing: 12) {
            Label("\(detectedJointCount)/21 joints", systemImage: "circle.grid.cross.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(detectedJointCount > 15 ? DS.lime : detectedJointCount > 8 ? .orange : .red)

            Spacer()

            if !session.hands.isEmpty {
                qualityBadge
            }

            Text(chiralityLabel)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(DS.textSecondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private var qualityBadge: some View {
        let pct = detectedJointCount * 100 / 21
        let color: Color = pct > 80 ? DS.lime : pct > 50 ? .orange : .red
        return Text("\(pct)%")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(.black)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(color)
            .clipShape(Capsule())
    }

    // MARK: - Finger bars

    private var fingerPanel: some View {
        VStack(spacing: 8) {
            // Legend
            HStack {
                Text("CURL DEPTH")
                    .font(.system(size: 10, weight: .bold)).tracking(1)
                    .foregroundStyle(DS.textTertiary)
                Spacer()
                Text("TOP = PROXIMAL · BOTTOM = DISTAL")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(DS.textTertiary)
            }

            HStack(spacing: 8) {
                let fingers = fingerColumns()
                ForEach(Array(fingers.enumerated()), id: \.offset) { i, tuple in
                    FingerColumn(label: tuple.0, color: tuple.1, data: tuple.2)
                }
            }
            .frame(height: 130)
            .padding(14)
            .background(DS.surface)
            .clipShape(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous))
        }
    }

    private func fingerColumns() -> [(String, Color, SingleFingerData)] {
        let placeholder = SingleFingerData(detected: false, proximalAngle: 0, distalAngle: 0)
        let all = session.allFingerData
        return [
            ("Thumb",  fingerColors[0], all?.thumb  ?? placeholder),
            ("Index",  fingerColors[1], all?.index  ?? placeholder),
            ("Middle", fingerColors[2], all?.middle ?? placeholder),
            ("Ring",   fingerColors[3], all?.ring   ?? placeholder),
            ("Little", fingerColors[4], all?.little ?? placeholder),
        ]
    }

    // MARK: - Permission denied

    private var permissionDeniedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .foregroundStyle(DS.textTertiary)
            Text("Camera access needed")
                .font(.headline).foregroundStyle(DS.textPrimary)
            Text("Enable camera in Settings to test finger detection.")
                .font(.callout).foregroundStyle(DS.textSecondary)
                .multilineTextAlignment(.center).padding(.horizontal, 32)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.black)
            .padding(.horizontal, 28).padding(.vertical, 12)
            .background(DS.lime)
            .clipShape(Capsule())
        }
    }
}
