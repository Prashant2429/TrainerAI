import SwiftUI

// MARK: - Muscle zone definitions

private struct MuscleZone: Identifiable {
    let id: String
    let keywords: [String]
    let rects: [CGRect]
}

private let muscleZones: [MuscleZone] = [
    MuscleZone(id: "chest",
               keywords: ["pector", "chest"],
               rects: [CGRect(x: 0.34, y: 0.21, width: 0.32, height: 0.10)]),
    MuscleZone(id: "shoulders",
               keywords: ["delt", "shoulder"],
               rects: [CGRect(x: 0.14, y: 0.20, width: 0.13, height: 0.09),
                       CGRect(x: 0.73, y: 0.20, width: 0.13, height: 0.09)]),
    MuscleZone(id: "biceps",
               keywords: ["bicep", "brachialis"],
               rects: [CGRect(x: 0.14, y: 0.29, width: 0.12, height: 0.11),
                       CGRect(x: 0.74, y: 0.29, width: 0.12, height: 0.11)]),
    MuscleZone(id: "triceps",
               keywords: ["tricep"],
               rects: [CGRect(x: 0.14, y: 0.30, width: 0.12, height: 0.10),
                       CGRect(x: 0.74, y: 0.30, width: 0.12, height: 0.10)]),
    MuscleZone(id: "forearms",
               keywords: ["forearm", "brachioradial"],
               rects: [CGRect(x: 0.10, y: 0.42, width: 0.10, height: 0.12),
                       CGRect(x: 0.80, y: 0.42, width: 0.10, height: 0.12)]),
    MuscleZone(id: "lats",
               keywords: ["lat", "latissimus"],
               rects: [CGRect(x: 0.28, y: 0.28, width: 0.10, height: 0.14),
                       CGRect(x: 0.62, y: 0.28, width: 0.10, height: 0.14)]),
    MuscleZone(id: "traps",
               keywords: ["trap"],
               rects: [CGRect(x: 0.35, y: 0.18, width: 0.30, height: 0.08)]),
    MuscleZone(id: "core",
               keywords: ["core", "abs", "rectus", "oblique", "serratus"],
               rects: [CGRect(x: 0.37, y: 0.31, width: 0.26, height: 0.14)]),
    MuscleZone(id: "lower_back",
               keywords: ["lower back", "erector", "lumbar"],
               rects: [CGRect(x: 0.37, y: 0.39, width: 0.26, height: 0.08)]),
    MuscleZone(id: "glutes",
               keywords: ["glut"],
               rects: [CGRect(x: 0.33, y: 0.47, width: 0.34, height: 0.09)]),
    MuscleZone(id: "hip",
               keywords: ["hip flexor", "iliopsoas"],
               rects: [CGRect(x: 0.38, y: 0.52, width: 0.24, height: 0.07)]),
    MuscleZone(id: "quads",
               keywords: ["quad"],
               rects: [CGRect(x: 0.31, y: 0.58, width: 0.15, height: 0.16),
                       CGRect(x: 0.54, y: 0.58, width: 0.15, height: 0.16)]),
    MuscleZone(id: "hamstrings",
               keywords: ["hamstring"],
               rects: [CGRect(x: 0.31, y: 0.60, width: 0.15, height: 0.14),
                       CGRect(x: 0.54, y: 0.60, width: 0.15, height: 0.14)]),
    MuscleZone(id: "calves",
               keywords: ["calf", "calves", "gastro", "soleus"],
               rects: [CGRect(x: 0.33, y: 0.78, width: 0.12, height: 0.14),
                       CGRect(x: 0.54, y: 0.78, width: 0.12, height: 0.14)]),
]

// MARK: - Muscle highlight view

struct MuscleMapView: View {
    let musclesTargeted: [String]
    let phase: Double

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
                drawSilhouette(into: &ctx, size: size)
            }
            Canvas { ctx, size in
                drawZones(into: &ctx, size: size, active: active, glowPass: true, pulse: p)
            }
            .blur(radius: 14)

            Canvas { ctx, size in
                drawZones(into: &ctx, size: size, active: active, glowPass: false, pulse: p)
            }

            // Targeted muscle labels
            GeometryReader { geo in
                let w = geo.size.width, h = geo.size.height
                ForEach(muscleZones.filter { active.contains($0.id) }) { zone in
                    if let first = zone.rects.first {
                        Text(zoneName(zone.id))
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(Color(red: 0.1, green: 0.1, blue: 0.0))
                            .position(
                                x: (first.midX) * w,
                                y: (first.midY) * h
                            )
                    }
                }
            }
        }
    }

    private func zoneName(_ id: String) -> String {
        switch id {
        case "chest":      return "Chest"
        case "shoulders":  return "Delts"
        case "biceps":     return "Biceps"
        case "triceps":    return "Triceps"
        case "forearms":   return "Forearms"
        case "lats":       return "Lats"
        case "traps":      return "Traps"
        case "core":       return "Core"
        case "lower_back": return "Lower Back"
        case "glutes":     return "Glutes"
        case "hip":        return "Hip Flex"
        case "quads":      return "Quads"
        case "hamstrings": return "Hamstrings"
        case "calves":     return "Calves"
        default:           return id
        }
    }

    private func drawSilhouette(into ctx: inout GraphicsContext, size: CGSize) {
        let w = size.width, h = size.height
        let c = GraphicsContext.Shading.color(.white.opacity(0.13))

        func ell(_ x: CGFloat, _ y: CGFloat, _ wd: CGFloat, _ ht: CGFloat) {
            ctx.fill(Path(ellipseIn: CGRect(x: x*w, y: y*h, width: wd*w, height: ht*h)), with: c)
        }
        func rr(_ x: CGFloat, _ y: CGFloat, _ wd: CGFloat, _ ht: CGFloat, r: CGFloat = 6) {
            ctx.fill(Path(roundedRect: CGRect(x: x*w, y: y*h, width: wd*w, height: ht*h), cornerRadius: r), with: c)
        }

        ell(0.39, 0.01, 0.22, 0.13)            // head
        rr(0.45, 0.13, 0.10, 0.05)             // neck
        rr(0.28, 0.18, 0.44, 0.30, r: 10)     // torso
        rr(0.30, 0.47, 0.40, 0.10, r: 8)      // pelvis
        rr(0.14, 0.20, 0.13, 0.20, r: 7)      // L upper arm
        rr(0.73, 0.20, 0.13, 0.20, r: 7)      // R upper arm
        rr(0.10, 0.40, 0.11, 0.18, r: 6)      // L forearm
        rr(0.79, 0.40, 0.11, 0.18, r: 6)      // R forearm
        rr(0.31, 0.56, 0.17, 0.22, r: 8)      // L thigh
        rr(0.52, 0.56, 0.17, 0.22, r: 8)      // R thigh
        rr(0.33, 0.78, 0.13, 0.17, r: 6)      // L calf
        rr(0.54, 0.78, 0.13, 0.17, r: 6)      // R calf
    }

    private func drawZones(into ctx: inout GraphicsContext, size: CGSize,
                           active: Set<String>, glowPass: Bool, pulse: Double) {
        let w = size.width, h = size.height
        let lime = Color(red: 0.78, green: 1.0, blue: 0.18)

        for zone in muscleZones {
            let isActive = active.contains(zone.id)
            for rect in zone.rects {
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
                    .padding(.top, 32).padding(.horizontal, 20).padding(.bottom, 20)

                    // Muscle map
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(DS.surface)
                        VStack(spacing: 6) {
                            MuscleMapView(musclesTargeted: exercise.musclesTargeted, phase: phase)
                                .frame(height: 200)
                                .padding(.horizontal, 12)
                            Text("Targeted muscles")
                                .font(.caption2)
                                .foregroundStyle(DS.textSecondary.opacity(0.6))
                                .padding(.bottom, 10)
                        }
                        .padding(.top, 12)
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
