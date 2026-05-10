import SwiftUI
import SceneKit

// MARK: - Exercise keyframe poses

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

    static func interpolated(from: [String: CGPoint], to: [String: CGPoint], t: Double) -> [String: CGPoint] {
        var result: [String: CGPoint] = [:]
        for (key, aPoint) in from { result[key] = lerp(aPoint, to[key] ?? aPoint, t: t) }
        return result
    }
}

// MARK: - Body segment definitions

private struct BodySegment {
    let id: String
    let from: String
    let to: String
    let muscleKeywords: [String]
}

private let bodySegments: [BodySegment] = [
    BodySegment(id: "neck_l_shoulder",  from: "neck",          to: "leftShoulder",  muscleKeywords: ["trap", "delt", "shoulder"]),
    BodySegment(id: "neck_r_shoulder",  from: "neck",          to: "rightShoulder", muscleKeywords: ["trap", "delt", "shoulder"]),
    BodySegment(id: "l_upper_arm",      from: "leftShoulder",  to: "leftElbow",     muscleKeywords: ["bicep", "tricep", "delt", "brachialis"]),
    BodySegment(id: "l_lower_arm",      from: "leftElbow",     to: "leftWrist",     muscleKeywords: ["bicep", "tricep", "forearm", "brachioradial"]),
    BodySegment(id: "r_upper_arm",      from: "rightShoulder", to: "rightElbow",    muscleKeywords: ["bicep", "tricep", "delt", "brachialis"]),
    BodySegment(id: "r_lower_arm",      from: "rightElbow",    to: "rightWrist",    muscleKeywords: ["bicep", "tricep", "forearm", "brachioradial"]),
    BodySegment(id: "l_torso",          from: "leftShoulder",  to: "leftHip",       muscleKeywords: ["pector", "chest", "lat", "oblique", "serratus", "core", "abs", "rectus", "erector", "lower back", "trap"]),
    BodySegment(id: "r_torso",          from: "rightShoulder", to: "rightHip",      muscleKeywords: ["pector", "chest", "lat", "oblique", "serratus", "core", "abs", "rectus", "erector", "lower back", "trap"]),
    BodySegment(id: "hip_span",         from: "leftHip",       to: "rightHip",      muscleKeywords: ["glut", "hip", "iliopsoas", "core"]),
    BodySegment(id: "l_thigh",          from: "leftHip",       to: "leftKnee",      muscleKeywords: ["quad", "hamstring", "glut", "hip"]),
    BodySegment(id: "r_thigh",          from: "rightHip",      to: "rightKnee",     muscleKeywords: ["quad", "hamstring", "glut", "hip"]),
    BodySegment(id: "l_calf",           from: "leftKnee",      to: "leftAnkle",     muscleKeywords: ["calf", "calves", "gastro", "soleus", "quad"]),
    BodySegment(id: "r_calf",           from: "rightKnee",     to: "rightAnkle",    muscleKeywords: ["calf", "calves", "gastro", "soleus", "quad"]),
]

private func activeSegments(for targets: [String]) -> Set<String> {
    let lower = targets.map { $0.lowercased() }
    var active = Set<String>()
    for seg in bodySegments {
        for kw in seg.muscleKeywords where lower.contains(where: { $0.contains(kw) }) {
            active.insert(seg.id)
            break
        }
    }
    return active
}

// MARK: - 3D humanoid with muscle highlighting

struct HumanBodySceneView: UIViewRepresentable {
    let joints: [String: CGPoint]
    let activeSegmentIds: Set<String>
    let pulse: Double

    private static func zOffset(_ j: String) -> Float {
        j.hasPrefix("right") ? 0.08 : j.hasPrefix("left") ? -0.08 : 0
    }

    private static func toSCN(_ pt: CGPoint, z: Float = 0) -> SCNVector3 {
        SCNVector3(Float(pt.x - 0.5) * 2.2, Float(-(pt.y - 0.5)) * 2.2, z)
    }

    private static func orient(_ node: SCNNode, from a: SCNVector3, to b: SCNVector3) {
        let dx = b.x - a.x, dy = b.y - a.y, dz = b.z - a.z
        let len = sqrt(dx*dx + dy*dy + dz*dz)
        guard len > 0.001 else { return }
        node.position = SCNVector3((a.x+b.x)/2, (a.y+b.y)/2, (a.z+b.z)/2)
        (node.geometry as? SCNCapsule)?.height = CGFloat(len)
        let ny = dy / len
        let angle = acos(max(-1, min(1, ny)))
        if angle < 0.001 { node.rotation = SCNVector4(0,0,1,0); return }
        if abs(angle - Float.pi) < 0.001 { node.rotation = SCNVector4(1,0,0,Float.pi); return }
        node.rotation = SCNVector4(-dz/len, 0, dx/len, angle)
    }

    private static func boneMat() -> SCNMaterial {
        let m = SCNMaterial()
        m.diffuse.contents  = UIColor(red: 0.90, green: 0.88, blue: 0.82, alpha: 1)
        m.specular.contents = UIColor.white
        m.shininess = 60
        m.lightingModel = .phong
        return m
    }

    private static func bodyMat() -> SCNMaterial {
        let m = SCNMaterial()
        m.diffuse.contents  = UIColor(red: 0.04, green: 0.16, blue: 0.32, alpha: 1)
        m.specular.contents = UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1)
        m.shininess = 50
        m.transparency = 0.42
        m.lightingModel = .phong
        return m
    }

    private static func activeMat(pulse: Double) -> SCNMaterial {
        let m = SCNMaterial()
        let a = CGFloat(0.60 + 0.28 * pulse)
        m.diffuse.contents  = UIColor(red: 0.78, green: 1.0, blue: 0.18, alpha: a)
        m.emission.contents = UIColor(red: 0.25, green: 0.55, blue: 0.0, alpha: 0.35)
        m.specular.contents = UIColor.white
        m.shininess = 80
        m.lightingModel = .phong
        return m
    }

    func makeUIView(context: Context) -> SCNView {
        let sv = SCNView()
        sv.backgroundColor = .clear
        sv.antialiasingMode = .multisampling4X
        sv.allowsCameraControl = false
        sv.scene = buildScene()
        return sv
    }

    private func buildScene() -> SCNScene {
        let scene = SCNScene()

        // Camera — slight 3/4 angle for depth
        let cam = SCNNode()
        cam.camera = SCNCamera()
        cam.camera?.fieldOfView = 46
        cam.position = SCNVector3(0.15, 0, 3.8)
        cam.eulerAngles = SCNVector3(0, -0.04, 0)
        scene.rootNode.addChildNode(cam)

        // Key light from top-left
        let key = SCNNode()
        key.light = SCNLight(); key.light?.type = .directional
        key.light?.intensity = 1100; key.light?.color = UIColor.white
        key.eulerAngles = SCNVector3(-0.5, 0.5, 0)
        scene.rootNode.addChildNode(key)

        // Ambient fill — cool blue matches body color
        let amb = SCNNode()
        amb.light = SCNLight(); amb.light?.type = .ambient
        amb.light?.intensity = 450
        amb.light?.color = UIColor(red: 0.6, green: 0.75, blue: 1.0, alpha: 1)
        scene.rootNode.addChildNode(amb)

        // Rim light from behind — lime tinted for active glow
        let rim = SCNNode()
        rim.light = SCNLight(); rim.light?.type = .omni
        rim.light?.intensity = 350
        rim.light?.color = UIColor(red: 0.78, green: 1.0, blue: 0.18, alpha: 1)
        rim.position = SCNVector3(-0.8, 0.3, -2.5)
        scene.rootNode.addChildNode(rim)

        // Head
        addHead(to: scene)

        // Segments
        for seg in bodySegments {
            let pa = joints[seg.from] ?? CGPoint(x: 0.5, y: 0.5)
            let pb = joints[seg.to]   ?? CGPoint(x: 0.5, y: 0.5)
            let a  = Self.toSCN(pa, z: Self.zOffset(seg.from))
            let b  = Self.toSCN(pb, z: Self.zOffset(seg.to))
            let isActive = activeSegmentIds.contains(seg.id)
            addSegment(seg.id, from: a, to: b, active: isActive, to: scene)
        }

        return scene
    }

    private func addHead(to scene: SCNScene) {
        // Skull (inner bone)
        let skull = SCNSphere(radius: 0.10)
        skull.firstMaterial = Self.boneMat()
        let skullNode = SCNNode(geometry: skull)
        skullNode.name = "head_bone"
        if let pt = joints["nose"] { skullNode.position = Self.toSCN(pt) }
        scene.rootNode.addChildNode(skullNode)

        // Head flesh (outer)
        let head = SCNSphere(radius: 0.13)
        head.firstMaterial = Self.bodyMat()
        let headNode = SCNNode(geometry: head)
        headNode.name = "head_body"
        if let pt = joints["nose"] { headNode.position = Self.toSCN(pt) }
        scene.rootNode.addChildNode(headNode)
    }

    private func addSegment(_ id: String, from a: SCNVector3, to b: SCNVector3,
                            active: Bool, to scene: SCNScene) {
        // Inner bone
        let boneGeo = SCNCapsule(capRadius: 0.028, height: 0.1)
        boneGeo.firstMaterial = Self.boneMat()
        let boneNode = SCNNode(geometry: boneGeo)
        boneNode.name = "bone_\(id)"
        Self.orient(boneNode, from: a, to: b)
        scene.rootNode.addChildNode(boneNode)

        // Outer muscle/body layer
        let bodyGeo = SCNCapsule(capRadius: 0.055, height: 0.1)
        bodyGeo.firstMaterial = active ? Self.activeMat(pulse: pulse) : Self.bodyMat()
        let bodyNode = SCNNode(geometry: bodyGeo)
        bodyNode.name = "body_\(id)"
        Self.orient(bodyNode, from: a, to: b)
        scene.rootNode.addChildNode(bodyNode)
    }

    func updateUIView(_ sv: SCNView, context: Context) {
        guard let scene = sv.scene else { return }
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.04

        // Head
        for name in ["head_bone", "head_body"] {
            if let n = scene.rootNode.childNode(withName: name, recursively: false),
               let pt = joints["nose"] {
                n.position = Self.toSCN(pt)
            }
        }

        // Segments
        for seg in bodySegments {
            let pa = joints[seg.from] ?? CGPoint(x: 0.5, y: 0.5)
            let pb = joints[seg.to]   ?? CGPoint(x: 0.5, y: 0.5)
            let a  = Self.toSCN(pa, z: Self.zOffset(seg.from))
            let b  = Self.toSCN(pb, z: Self.zOffset(seg.to))
            let isActive = activeSegmentIds.contains(seg.id)

            if let n = scene.rootNode.childNode(withName: "bone_\(seg.id)", recursively: false) {
                Self.orient(n, from: a, to: b)
            }
            if let n = scene.rootNode.childNode(withName: "body_\(seg.id)", recursively: false) {
                Self.orient(n, from: a, to: b)
                n.geometry?.firstMaterial = isActive ? Self.activeMat(pulse: pulse) : Self.bodyMat()
            }
        }

        SCNTransaction.commit()
    }
}

// MARK: - Exercise demo overlay

struct ExerciseDemoView: View {
    let exercise: Exercise
    let onStart: () -> Void

    @State private var phase: Double = 0
    private let timer = Timer.publish(every: 0.033, on: .main, in: .common).autoconnect()

    private var currentJoints: [String: CGPoint] {
        let t = (sin(phase - .pi / 2) + 1) / 2
        return ExercisePoses.interpolated(
            from: ExercisePoses.standing,
            to: ExercisePoses.movementPose(for: exercise.id),
            t: t
        )
    }

    private var activeSeg: Set<String> { activeSegments(for: exercise.musclesTargeted) }
    private var pulse: Double { (sin(phase * 0.8) + 1) / 2 }

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
                    .padding(.top, 32).padding(.horizontal, 20).padding(.bottom, 16)

                    // 3D humanoid with muscle highlighting
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color(red: 0.03, green: 0.07, blue: 0.16))

                        HumanBodySceneView(joints: currentJoints,
                                           activeSegmentIds: activeSeg,
                                           pulse: pulse)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                        // Muscle labels overlay
                        VStack {
                            Spacer()
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(exercise.musclesTargeted.prefix(4), id: \.self) { m in
                                        Text(m)
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(.black)
                                            .padding(.horizontal, 7).padding(.vertical, 3)
                                            .background(DS.lime)
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(.horizontal, 12).padding(.bottom, 10)
                            }
                        }
                    }
                    .frame(height: 280)
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
        .onReceive(timer) { _ in phase += 0.04 }
    }
}
