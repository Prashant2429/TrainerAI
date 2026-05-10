import SwiftUI
import SceneKit

// MARK: - Demo keyframe data

private enum ExercisePoses {

    static let standing: [String: CGPoint] = [
        "nose":          CGPoint(x: 0.50, y: 0.05),
        "neck":          CGPoint(x: 0.50, y: 0.14),
        "leftShoulder":  CGPoint(x: 0.36, y: 0.21),
        "rightShoulder": CGPoint(x: 0.64, y: 0.21),
        "leftElbow":     CGPoint(x: 0.30, y: 0.36),
        "rightElbow":    CGPoint(x: 0.70, y: 0.36),
        "leftWrist":     CGPoint(x: 0.27, y: 0.50),
        "rightWrist":    CGPoint(x: 0.73, y: 0.50),
        "leftHip":       CGPoint(x: 0.41, y: 0.50),
        "rightHip":      CGPoint(x: 0.59, y: 0.50),
        "leftKnee":      CGPoint(x: 0.41, y: 0.70),
        "rightKnee":     CGPoint(x: 0.59, y: 0.70),
        "leftAnkle":     CGPoint(x: 0.41, y: 0.90),
        "rightAnkle":    CGPoint(x: 0.59, y: 0.90),
    ]

    static func movementPose(for exerciseId: String) -> [String: CGPoint] {
        switch exerciseId {
        case "squat", "goblet_squat", "leg_press", "leg_extension", "leg_curl":
            return squatBottom
        case "deadlift", "romanian_deadlift", "hip_thrust":
            return deadliftHinge
        case "bicep_curl":
            return bicepCurlTop
        case "ohp", "arnold_press":
            return ohpTop
        case "barbell_row", "cable_row":
            return rowPulled
        case "lateral_raise":
            return lateralRaiseTop
        case "bench_press", "incline_press", "skull_crusher":
            return pressBottom
        case "lunge":
            return lungeBottom
        case "cable_pushdown":
            return pushdownBottom
        default:
            return genericCurlTop
        }
    }

    static let squatBottom: [String: CGPoint] = [
        "nose":          CGPoint(x: 0.50, y: 0.27),
        "neck":          CGPoint(x: 0.50, y: 0.37),
        "leftShoulder":  CGPoint(x: 0.36, y: 0.44),
        "rightShoulder": CGPoint(x: 0.64, y: 0.44),
        "leftElbow":     CGPoint(x: 0.29, y: 0.58),
        "rightElbow":    CGPoint(x: 0.71, y: 0.58),
        "leftWrist":     CGPoint(x: 0.28, y: 0.68),
        "rightWrist":    CGPoint(x: 0.72, y: 0.68),
        "leftHip":       CGPoint(x: 0.37, y: 0.65),
        "rightHip":      CGPoint(x: 0.63, y: 0.65),
        "leftKnee":      CGPoint(x: 0.30, y: 0.76),
        "rightKnee":     CGPoint(x: 0.70, y: 0.76),
        "leftAnkle":     CGPoint(x: 0.37, y: 0.91),
        "rightAnkle":    CGPoint(x: 0.63, y: 0.91),
    ]

    static let deadliftHinge: [String: CGPoint] = [
        "nose":          CGPoint(x: 0.50, y: 0.18),
        "neck":          CGPoint(x: 0.50, y: 0.26),
        "leftShoulder":  CGPoint(x: 0.37, y: 0.33),
        "rightShoulder": CGPoint(x: 0.63, y: 0.33),
        "leftElbow":     CGPoint(x: 0.36, y: 0.49),
        "rightElbow":    CGPoint(x: 0.64, y: 0.49),
        "leftWrist":     CGPoint(x: 0.39, y: 0.62),
        "rightWrist":    CGPoint(x: 0.61, y: 0.62),
        "leftHip":       CGPoint(x: 0.41, y: 0.51),
        "rightHip":      CGPoint(x: 0.59, y: 0.51),
        "leftKnee":      CGPoint(x: 0.41, y: 0.67),
        "rightKnee":     CGPoint(x: 0.59, y: 0.67),
        "leftAnkle":     CGPoint(x: 0.41, y: 0.90),
        "rightAnkle":    CGPoint(x: 0.59, y: 0.90),
    ]

    static let bicepCurlTop: [String: CGPoint] = [
        "nose":          CGPoint(x: 0.50, y: 0.05),
        "neck":          CGPoint(x: 0.50, y: 0.14),
        "leftShoulder":  CGPoint(x: 0.36, y: 0.21),
        "rightShoulder": CGPoint(x: 0.64, y: 0.21),
        "leftElbow":     CGPoint(x: 0.36, y: 0.29),
        "rightElbow":    CGPoint(x: 0.64, y: 0.29),
        "leftWrist":     CGPoint(x: 0.30, y: 0.14),
        "rightWrist":    CGPoint(x: 0.70, y: 0.14),
        "leftHip":       CGPoint(x: 0.41, y: 0.50),
        "rightHip":      CGPoint(x: 0.59, y: 0.50),
        "leftKnee":      CGPoint(x: 0.41, y: 0.70),
        "rightKnee":     CGPoint(x: 0.59, y: 0.70),
        "leftAnkle":     CGPoint(x: 0.41, y: 0.90),
        "rightAnkle":    CGPoint(x: 0.59, y: 0.90),
    ]

    static let ohpTop: [String: CGPoint] = [
        "nose":          CGPoint(x: 0.50, y: 0.05),
        "neck":          CGPoint(x: 0.50, y: 0.14),
        "leftShoulder":  CGPoint(x: 0.36, y: 0.21),
        "rightShoulder": CGPoint(x: 0.64, y: 0.21),
        "leftElbow":     CGPoint(x: 0.27, y: 0.10),
        "rightElbow":    CGPoint(x: 0.73, y: 0.10),
        "leftWrist":     CGPoint(x: 0.25, y: 0.00),
        "rightWrist":    CGPoint(x: 0.75, y: 0.00),
        "leftHip":       CGPoint(x: 0.41, y: 0.50),
        "rightHip":      CGPoint(x: 0.59, y: 0.50),
        "leftKnee":      CGPoint(x: 0.41, y: 0.70),
        "rightKnee":     CGPoint(x: 0.59, y: 0.70),
        "leftAnkle":     CGPoint(x: 0.41, y: 0.90),
        "rightAnkle":    CGPoint(x: 0.59, y: 0.90),
    ]

    static let rowPulled: [String: CGPoint] = [
        "nose":          CGPoint(x: 0.50, y: 0.15),
        "neck":          CGPoint(x: 0.50, y: 0.23),
        "leftShoulder":  CGPoint(x: 0.36, y: 0.30),
        "rightShoulder": CGPoint(x: 0.64, y: 0.30),
        "leftElbow":     CGPoint(x: 0.31, y: 0.42),
        "rightElbow":    CGPoint(x: 0.69, y: 0.42),
        "leftWrist":     CGPoint(x: 0.39, y: 0.50),
        "rightWrist":    CGPoint(x: 0.61, y: 0.50),
        "leftHip":       CGPoint(x: 0.41, y: 0.50),
        "rightHip":      CGPoint(x: 0.59, y: 0.50),
        "leftKnee":      CGPoint(x: 0.41, y: 0.67),
        "rightKnee":     CGPoint(x: 0.59, y: 0.67),
        "leftAnkle":     CGPoint(x: 0.41, y: 0.90),
        "rightAnkle":    CGPoint(x: 0.59, y: 0.90),
    ]

    static let lateralRaiseTop: [String: CGPoint] = [
        "nose":          CGPoint(x: 0.50, y: 0.05),
        "neck":          CGPoint(x: 0.50, y: 0.14),
        "leftShoulder":  CGPoint(x: 0.36, y: 0.21),
        "rightShoulder": CGPoint(x: 0.64, y: 0.21),
        "leftElbow":     CGPoint(x: 0.16, y: 0.27),
        "rightElbow":    CGPoint(x: 0.84, y: 0.27),
        "leftWrist":     CGPoint(x: 0.06, y: 0.31),
        "rightWrist":    CGPoint(x: 0.94, y: 0.31),
        "leftHip":       CGPoint(x: 0.41, y: 0.50),
        "rightHip":      CGPoint(x: 0.59, y: 0.50),
        "leftKnee":      CGPoint(x: 0.41, y: 0.70),
        "rightKnee":     CGPoint(x: 0.59, y: 0.70),
        "leftAnkle":     CGPoint(x: 0.41, y: 0.90),
        "rightAnkle":    CGPoint(x: 0.59, y: 0.90),
    ]

    static let pressBottom: [String: CGPoint] = [
        "nose":          CGPoint(x: 0.50, y: 0.05),
        "neck":          CGPoint(x: 0.50, y: 0.14),
        "leftShoulder":  CGPoint(x: 0.36, y: 0.21),
        "rightShoulder": CGPoint(x: 0.64, y: 0.21),
        "leftElbow":     CGPoint(x: 0.21, y: 0.31),
        "rightElbow":    CGPoint(x: 0.79, y: 0.31),
        "leftWrist":     CGPoint(x: 0.36, y: 0.22),
        "rightWrist":    CGPoint(x: 0.64, y: 0.22),
        "leftHip":       CGPoint(x: 0.41, y: 0.50),
        "rightHip":      CGPoint(x: 0.59, y: 0.50),
        "leftKnee":      CGPoint(x: 0.41, y: 0.70),
        "rightKnee":     CGPoint(x: 0.59, y: 0.70),
        "leftAnkle":     CGPoint(x: 0.41, y: 0.90),
        "rightAnkle":    CGPoint(x: 0.59, y: 0.90),
    ]

    static let lungeBottom: [String: CGPoint] = [
        "nose":          CGPoint(x: 0.50, y: 0.13),
        "neck":          CGPoint(x: 0.50, y: 0.22),
        "leftShoulder":  CGPoint(x: 0.36, y: 0.29),
        "rightShoulder": CGPoint(x: 0.64, y: 0.29),
        "leftElbow":     CGPoint(x: 0.30, y: 0.43),
        "rightElbow":    CGPoint(x: 0.70, y: 0.43),
        "leftWrist":     CGPoint(x: 0.28, y: 0.57),
        "rightWrist":    CGPoint(x: 0.72, y: 0.57),
        "leftHip":       CGPoint(x: 0.42, y: 0.56),
        "rightHip":      CGPoint(x: 0.58, y: 0.56),
        "leftKnee":      CGPoint(x: 0.35, y: 0.73),
        "rightKnee":     CGPoint(x: 0.60, y: 0.70),
        "leftAnkle":     CGPoint(x: 0.32, y: 0.91),
        "rightAnkle":    CGPoint(x: 0.62, y: 0.91),
    ]

    static let pushdownBottom: [String: CGPoint] = [
        "nose":          CGPoint(x: 0.50, y: 0.05),
        "neck":          CGPoint(x: 0.50, y: 0.14),
        "leftShoulder":  CGPoint(x: 0.36, y: 0.21),
        "rightShoulder": CGPoint(x: 0.64, y: 0.21),
        "leftElbow":     CGPoint(x: 0.39, y: 0.28),
        "rightElbow":    CGPoint(x: 0.61, y: 0.28),
        "leftWrist":     CGPoint(x: 0.37, y: 0.48),
        "rightWrist":    CGPoint(x: 0.63, y: 0.48),
        "leftHip":       CGPoint(x: 0.41, y: 0.50),
        "rightHip":      CGPoint(x: 0.59, y: 0.50),
        "leftKnee":      CGPoint(x: 0.41, y: 0.70),
        "rightKnee":     CGPoint(x: 0.59, y: 0.70),
        "leftAnkle":     CGPoint(x: 0.41, y: 0.90),
        "rightAnkle":    CGPoint(x: 0.59, y: 0.90),
    ]

    static let genericCurlTop: [String: CGPoint] = [
        "nose":          CGPoint(x: 0.50, y: 0.05),
        "neck":          CGPoint(x: 0.50, y: 0.14),
        "leftShoulder":  CGPoint(x: 0.36, y: 0.21),
        "rightShoulder": CGPoint(x: 0.64, y: 0.21),
        "leftElbow":     CGPoint(x: 0.36, y: 0.29),
        "rightElbow":    CGPoint(x: 0.64, y: 0.29),
        "leftWrist":     CGPoint(x: 0.32, y: 0.16),
        "rightWrist":    CGPoint(x: 0.68, y: 0.16),
        "leftHip":       CGPoint(x: 0.41, y: 0.50),
        "rightHip":      CGPoint(x: 0.59, y: 0.50),
        "leftKnee":      CGPoint(x: 0.41, y: 0.70),
        "rightKnee":     CGPoint(x: 0.59, y: 0.70),
        "leftAnkle":     CGPoint(x: 0.41, y: 0.90),
        "rightAnkle":    CGPoint(x: 0.59, y: 0.90),
    ]

    static func lerp(_ a: CGPoint, _ b: CGPoint, t: Double) -> CGPoint {
        CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
    }

    static func interpolated(
        from: [String: CGPoint],
        to: [String: CGPoint],
        t: Double
    ) -> [String: CGPoint] {
        var result: [String: CGPoint] = [:]
        for (key, aPoint) in from {
            result[key] = lerp(aPoint, to[key] ?? aPoint, t: t)
        }
        return result
    }
}

// MARK: - Exercise demo overlay

struct ExerciseDemoView: View {
    let exercise: Exercise
    let onStart: () -> Void

    @State private var phase: Double = 0
    private let timer = Timer.publish(every: 0.033, on: .main, in: .common).autoconnect()

    private var startPose: [String: CGPoint] { ExercisePoses.standing }
    private var endPose: [String: CGPoint]   { ExercisePoses.movementPose(for: exercise.id) }

    private var currentPose: PoseData {
        // Smooth sinusoidal oscillation 0 → 1 → 0
        let t = (sin(phase - .pi / 2) + 1) / 2
        let joints = ExercisePoses.interpolated(from: startPose, to: endPose, t: t)
        return PoseData(joints: joints, confidence: [:])
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 6) {
                        Text(exercise.name)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                        Text(exercise.musclesTargeted.prefix(3).joined(separator: " · "))
                            .font(.caption)
                            .foregroundStyle(DS.textSecondary)
                    }
                    .padding(.top, 32).padding(.horizontal, 20).padding(.bottom, 20)

                    // 3D avatar
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(DS.surface)
                        HumanAvatarSceneView(joints: currentPose.joints)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    .frame(height: 260)
                    .padding(.horizontal, 20).padding(.bottom, 24)

                    // Step-by-step cues
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Form cues")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.bottom, 2)

                        ForEach(Array(exercise.stepByStepCues.enumerated()), id: \.offset) { i, cue in
                            HStack(alignment: .top, spacing: 10) {
                                Text("\(i + 1)")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.black)
                                    .frame(width: 20, height: 20)
                                    .background(DS.lime)
                                    .clipShape(Circle())
                                Text(cue)
                                    .font(.callout)
                                    .foregroundStyle(DS.textSecondary)
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 20).padding(.bottom, 16)

                    // Camera placement
                    HStack(spacing: 8) {
                        Image(systemName: "iphone.gen3")
                            .font(.caption).foregroundStyle(DS.lime)
                        Text(exercise.phonePlacementInstruction)
                            .font(.caption).foregroundStyle(DS.textSecondary)
                        Spacer()
                    }
                    .padding(.horizontal, 20).padding(.bottom, 32)

                    // Start button
                    Button(action: onStart) {
                        HStack(spacing: 10) {
                            Image(systemName: "play.circle.fill").font(.title3)
                            Text("Start Set 1").font(.system(size: 18, weight: .bold))
                        }
                        .dsAccentButton()
                        .shadow(color: DS.lime.opacity(0.30), radius: 10, y: 4)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20).padding(.bottom, 48)
                }
            }
        }
        .onReceive(timer) { _ in
            phase += 0.04  // ~5 second full cycle
        }
    }
}

// MARK: - SceneKit 3D humanoid avatar

struct HumanAvatarSceneView: UIViewRepresentable {

    let joints: [String: CGPoint]

    // Bone connections — each tuple is (startJoint, endJoint)
    private static let bones: [(String, String)] = [
        ("neck", "leftShoulder"),  ("neck", "rightShoulder"),
        ("leftShoulder", "leftElbow"),   ("leftElbow", "leftWrist"),
        ("rightShoulder", "rightElbow"), ("rightElbow", "rightWrist"),
        ("leftShoulder", "leftHip"),     ("rightShoulder", "rightHip"),
        ("leftHip", "rightHip"),
        ("leftHip", "leftKnee"),   ("leftKnee", "leftAnkle"),
        ("rightHip", "rightKnee"), ("rightKnee", "rightAnkle"),
    ]

    // Right-side joints sit slightly forward (+z), left-side slightly back (-z)
    private static func zOffset(_ joint: String) -> Float {
        joint.hasPrefix("right") ? 0.06 : joint.hasPrefix("left") ? -0.06 : 0
    }

    // Normalized 2D → SceneKit 3D
    private static func toSCN(_ pt: CGPoint, z: Float = 0) -> SCNVector3 {
        SCNVector3(Float(pt.x - 0.5) * 2.2, Float(-(pt.y - 0.5)) * 2.2, z)
    }

    // Point a capsule from a → b; updates its height and orientation
    private static func orient(_ node: SCNNode, from a: SCNVector3, to b: SCNVector3) {
        let dx = b.x - a.x, dy = b.y - a.y, dz = b.z - a.z
        let len = sqrt(dx*dx + dy*dy + dz*dz)
        guard len > 0.001 else { return }
        node.position = SCNVector3((a.x + b.x) / 2, (a.y + b.y) / 2, (a.z + b.z) / 2)
        (node.geometry as? SCNCapsule)?.height = CGFloat(len)
        let ny = dy / len
        let angle = acos(max(-1, min(1, ny)))
        if angle < 0.001 { node.rotation = SCNVector4(0, 0, 1, 0); return }
        if abs(angle - Float.pi) < 0.001 { node.rotation = SCNVector4(1, 0, 0, Float.pi); return }
        // Cross product of (dx,dy,dz)/len with Y-axis (0,1,0) = (-dz, 0, dx)
        let ax = -dz / len, az = dx / len
        node.rotation = SCNVector4(ax, 0, az, angle)
    }

    private static func limeMaterial() -> SCNMaterial {
        let mat = SCNMaterial()
        mat.diffuse.contents  = UIColor(red: 0.78, green: 1.00, blue: 0.18, alpha: 1)
        mat.specular.contents = UIColor.white
        mat.shininess = 80
        mat.lightingModel = .phong
        return mat
    }

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .clear
        scnView.antialiasingMode = .multisampling4X
        scnView.allowsCameraControl = false
        scnView.scene = buildScene()
        return scnView
    }

    private func buildScene() -> SCNScene {
        let scene = SCNScene()

        // Camera
        let cam = SCNNode()
        cam.camera = SCNCamera()
        cam.camera?.fieldOfView = 50
        cam.position = SCNVector3(0, 0, 3.5)
        scene.rootNode.addChildNode(cam)

        // Ambient light
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 400
        scene.rootNode.addChildNode(ambient)

        // Directional light from top-left
        let omni = SCNNode()
        omni.light = SCNLight()
        omni.light?.type = .omni
        omni.light?.intensity = 900
        omni.position = SCNVector3(1.5, 2.5, 3)
        scene.rootNode.addChildNode(omni)

        // Head sphere
        let headGeo = SCNSphere(radius: 0.13)
        headGeo.firstMaterial = Self.limeMaterial()
        let headNode = SCNNode(geometry: headGeo)
        headNode.name = "joint_nose"
        if let pt = joints["nose"] {
            headNode.position = Self.toSCN(pt, z: 0)
        }
        scene.rootNode.addChildNode(headNode)

        // Joint spheres at key nodes
        for name in ["neck", "leftShoulder", "rightShoulder", "leftHip", "rightHip",
                     "leftKnee", "rightKnee", "leftElbow", "rightElbow"] {
            let geo = SCNSphere(radius: 0.055)
            geo.firstMaterial = Self.limeMaterial()
            let node = SCNNode(geometry: geo)
            node.name = "joint_\(name)"
            if let pt = joints[name] {
                node.position = Self.toSCN(pt, z: Self.zOffset(name))
            }
            scene.rootNode.addChildNode(node)
        }

        // Bone capsules
        for (a, b) in Self.bones {
            let geo = SCNCapsule(capRadius: 0.048, height: 0.1)
            geo.firstMaterial = Self.limeMaterial()
            let node = SCNNode(geometry: geo)
            node.name = "bone_\(a)_\(b)"
            if let pa = joints[a], let pb = joints[b] {
                Self.orient(node,
                    from: Self.toSCN(pa, z: Self.zOffset(a)),
                    to:   Self.toSCN(pb, z: Self.zOffset(b)))
            }
            scene.rootNode.addChildNode(node)
        }

        return scene
    }

    func updateUIView(_ scnView: SCNView, context: Context) {
        guard let scene = scnView.scene else { return }
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.04

        // Update head
        if let node = scene.rootNode.childNode(withName: "joint_nose", recursively: false),
           let pt = joints["nose"] {
            node.position = Self.toSCN(pt, z: 0)
        }

        // Update joint spheres
        for name in ["neck", "leftShoulder", "rightShoulder", "leftHip", "rightHip",
                     "leftKnee", "rightKnee", "leftElbow", "rightElbow"] {
            if let node = scene.rootNode.childNode(withName: "joint_\(name)", recursively: false),
               let pt = joints[name] {
                node.position = Self.toSCN(pt, z: Self.zOffset(name))
            }
        }

        // Update bones
        for (a, b) in Self.bones {
            if let node = scene.rootNode.childNode(withName: "bone_\(a)_\(b)", recursively: false),
               let pa = joints[a], let pb = joints[b] {
                Self.orient(node,
                    from: Self.toSCN(pa, z: Self.zOffset(a)),
                    to:   Self.toSCN(pb, z: Self.zOffset(b)))
            }
        }

        SCNTransaction.commit()
    }
}
