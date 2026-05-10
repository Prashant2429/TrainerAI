import SwiftUI

// MARK: - Muscle zone definitions

private struct MuscleZone: Identifiable {
    let id: String
    let keywords: [String]
    let frontRects: [CGRect]   // normalized 0-1; empty = not visible on this face
    let backRects: [CGRect]
}

private let muscleZones: [MuscleZone] = [
    // FRONT-DOMINANT
    MuscleZone(id: "chest",
               keywords: ["pector", "chest"],
               frontRects: [CGRect(x: 0.32, y: 0.21, width: 0.36, height: 0.11)],
               backRects: []),
    MuscleZone(id: "shoulders",
               keywords: ["delt", "shoulder"],
               frontRects: [CGRect(x: 0.13, y: 0.19, width: 0.14, height: 0.09),
                            CGRect(x: 0.73, y: 0.19, width: 0.14, height: 0.09)],
               backRects: [CGRect(x: 0.13, y: 0.19, width: 0.14, height: 0.09),
                           CGRect(x: 0.73, y: 0.19, width: 0.14, height: 0.09)]),
    MuscleZone(id: "biceps",
               keywords: ["bicep", "brachialis"],
               frontRects: [CGRect(x: 0.13, y: 0.29, width: 0.12, height: 0.12),
                            CGRect(x: 0.75, y: 0.29, width: 0.12, height: 0.12)],
               backRects: []),
    MuscleZone(id: "triceps",
               keywords: ["tricep"],
               frontRects: [],
               backRects: [CGRect(x: 0.13, y: 0.29, width: 0.12, height: 0.12),
                           CGRect(x: 0.75, y: 0.29, width: 0.12, height: 0.12)]),
    MuscleZone(id: "forearms",
               keywords: ["forearm", "brachioradial"],
               frontRects: [CGRect(x: 0.10, y: 0.42, width: 0.10, height: 0.12),
                            CGRect(x: 0.80, y: 0.42, width: 0.10, height: 0.12)],
               backRects: [CGRect(x: 0.10, y: 0.42, width: 0.10, height: 0.12),
                           CGRect(x: 0.80, y: 0.42, width: 0.10, height: 0.12)]),
    // BACK-DOMINANT
    MuscleZone(id: "lats",
               keywords: ["lat", "latissimus"],
               frontRects: [],
               backRects: [CGRect(x: 0.29, y: 0.28, width: 0.11, height: 0.16),
                           CGRect(x: 0.60, y: 0.28, width: 0.11, height: 0.16)]),
    MuscleZone(id: "traps",
               keywords: ["trap"],
               frontRects: [],
               backRects: [CGRect(x: 0.33, y: 0.17, width: 0.34, height: 0.10)]),
    MuscleZone(id: "lower_back",
               keywords: ["lower back", "erector", "lumbar"],
               frontRects: [],
               backRects: [CGRect(x: 0.37, y: 0.39, width: 0.26, height: 0.09)]),
    MuscleZone(id: "glutes",
               keywords: ["glut"],
               frontRects: [],
               backRects: [CGRect(x: 0.32, y: 0.48, width: 0.36, height: 0.10)]),
    MuscleZone(id: "hamstrings",
               keywords: ["hamstring"],
               frontRects: [],
               backRects: [CGRect(x: 0.31, y: 0.59, width: 0.16, height: 0.17),
                           CGRect(x: 0.53, y: 0.59, width: 0.16, height: 0.17)]),
    // BOTH FACES
    MuscleZone(id: "core",
               keywords: ["core", "abs", "rectus", "oblique", "serratus"],
               frontRects: [CGRect(x: 0.37, y: 0.32, width: 0.26, height: 0.14)],
               backRects: []),
    MuscleZone(id: "hip",
               keywords: ["hip flexor", "iliopsoas"],
               frontRects: [CGRect(x: 0.38, y: 0.50, width: 0.24, height: 0.07)],
               backRects: []),
    MuscleZone(id: "quads",
               keywords: ["quad"],
               frontRects: [CGRect(x: 0.31, y: 0.58, width: 0.16, height: 0.17),
                            CGRect(x: 0.53, y: 0.58, width: 0.16, height: 0.17)],
               backRects: []),
    MuscleZone(id: "calves",
               keywords: ["calf", "calves", "gastro", "soleus"],
               frontRects: [CGRect(x: 0.33, y: 0.78, width: 0.13, height: 0.14),
                            CGRect(x: 0.53, y: 0.78, width: 0.13, height: 0.14)],
               backRects: [CGRect(x: 0.33, y: 0.78, width: 0.13, height: 0.14),
                           CGRect(x: 0.53, y: 0.78, width: 0.13, height: 0.14)]),
]

// MARK: - Muscle highlight view

struct MuscleMapView: View {
    let musclesTargeted: [String]
    let phase: Double
    let showBack: Bool

    private var pulse: Double { (sin(phase) + 1) / 2 }

    private var activeZoneIds: Set<String> {
        let lowercased = musclesTargeted.map { $0.lowercased() }
        var active = Set<String>()
        for zone in muscleZones {
            for kw in zone.keywords where lowercased.contains(where: { $0.contains(kw) }) {
                active.insert(zone.id)
                break
            }
        }
        return active
    }

    var body: some View {
        let active = activeZoneIds
        let p = pulse
        ZStack {
            Canvas { ctx, size in
                drawSilhouette(into: &ctx, size: size, back: showBack)
            }
            Canvas { ctx, size in
                drawZones(into: &ctx, size: size, active: active, glowPass: true, pulse: p)
            }
            .blur(radius: 14)
            Canvas { ctx, size in
                drawZones(into: &ctx, size: size, active: active, glowPass: false, pulse: p)
            }
        }
    }

    private func activeRects(for zone: MuscleZone) -> [CGRect] {
        showBack ? zone.backRects : zone.frontRects
    }

    private func drawSilhouette(into ctx: inout GraphicsContext, size: CGSize, back: Bool) {
        let w = size.width, h = size.height
        let c = GraphicsContext.Shading.color(.white.opacity(0.14))

        func ell(_ x: CGFloat, _ y: CGFloat, _ wd: CGFloat, _ ht: CGFloat) {
            ctx.fill(Path(ellipseIn: CGRect(x: x*w, y: y*h, width: wd*w, height: ht*h)), with: c)
        }
        func rr(_ x: CGFloat, _ y: CGFloat, _ wd: CGFloat, _ ht: CGFloat, r: CGFloat = 6) {
            ctx.fill(Path(roundedRect: CGRect(x: x*w, y: y*h, width: wd*w, height: ht*h), cornerRadius: r), with: c)
        }

        ell(0.39, 0.01, 0.22, 0.13)             // head
        rr(0.45, 0.13, 0.10, 0.05)              // neck
        rr(0.28, 0.18, 0.44, 0.30, r: 10)      // torso
        rr(0.30, 0.47, 0.40, 0.10, r: 8)       // pelvis
        rr(0.13, 0.19, 0.14, 0.21, r: 7)       // L upper arm
        rr(0.73, 0.19, 0.14, 0.21, r: 7)       // R upper arm
        rr(0.10, 0.40, 0.12, 0.18, r: 6)       // L forearm
        rr(0.78, 0.40, 0.12, 0.18, r: 6)       // R forearm
        rr(0.32, 0.56, 0.17, 0.22, r: 8)       // L thigh
        rr(0.51, 0.56, 0.17, 0.22, r: 8)       // R thigh
        rr(0.33, 0.78, 0.14, 0.17, r: 6)       // L calf
        rr(0.53, 0.78, 0.14, 0.17, r: 6)       // R calf

        if back {
            // Spine line hint on back view
            let spineColor = GraphicsContext.Shading.color(.white.opacity(0.06))
            ctx.fill(Path(roundedRect: CGRect(x: 0.485*w, y: 0.19*h,
                                             width: 0.03*w, height: 0.28*h), cornerRadius: 4), with: spineColor)
        }
    }

    private func drawZones(into ctx: inout GraphicsContext, size: CGSize,
                           active: Set<String>, glowPass: Bool, pulse: Double) {
        let w = size.width, h = size.height
        let lime = Color(red: 0.78, green: 1.0, blue: 0.18)

        for zone in muscleZones {
            let rects = showBack ? zone.backRects : zone.frontRects
            guard !rects.isEmpty else { continue }
            let isActive = active.contains(zone.id)
            for rect in rects {
                let scaled = CGRect(x: rect.minX * w, y: rect.minY * h,
                                    width: rect.width * w, height: rect.height * h)
                let path = Path(ellipseIn: scaled)
                if isActive {
                    let alpha = glowPass ? (0.35 + 0.45 * pulse) : (0.65 + 0.25 * pulse)
                    ctx.fill(path, with: .color(lime.opacity(alpha)))
                } else if !glowPass {
                    ctx.fill(path, with: .color(.white.opacity(0.07)))
                }
            }
        }
    }
}

// MARK: - Exercise demo overlay

struct ExerciseDemoView: View {
    let exercise: Exercise
    let onStart: () -> Void

    @State private var phase: Double = 0
    @State private var showBack = false
    private let timer = Timer.publish(every: 0.033, on: .main, in: .common).autoconnect()

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

                    // Front / Back toggle
                    HStack(spacing: 0) {
                        ForEach(["Front", "Back"], id: \.self) { label in
                            let isSelected = (label == "Back") == showBack
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) { showBack = label == "Back" }
                            } label: {
                                Text(label)
                                    .font(.callout.weight(isSelected ? .semibold : .medium))
                                    .foregroundStyle(isSelected ? .black : DS.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(isSelected ? DS.lime : Color.clear)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(4)
                    .background(DS.elevated)
                    .clipShape(Capsule())
                    .padding(.horizontal, 60).padding(.bottom, 14)

                    // Muscle map
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous).fill(DS.surface)
                        MuscleMapView(musclesTargeted: exercise.musclesTargeted, phase: phase, showBack: showBack)
                            .padding(14)
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
            phase += 0.04
        }
    }
}
