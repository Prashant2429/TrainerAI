import SwiftUI

struct WorkoutView: View {
    @EnvironmentObject var sessionManager: SessionManager
    var initialExerciseName: String? = nil

    @State private var selectedExercise: Exercise?
    @State private var showDebrief = false
    @State private var errorFlash: String? = nil
    @State private var exercises: [Exercise] = []
    @State private var selectedCategory: Exercise.Category? = nil

    private static let allCategories: [Exercise.Category] = [.compound, .isolation, .shoulder, .cable, .cardio]

    private var filteredExercises: [Exercise] {
        guard let cat = selectedCategory else { return exercises }
        return exercises.filter { $0.category == cat }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if showDebrief, let log = sessionManager.session.sessionLog.last {
                SetDebriefView(
                    setLog: log,
                    nextSetAction: {
                        showDebrief = false
                        if let ex = selectedExercise { sessionManager.startSet(exercise: ex) }
                    },
                    endWorkoutAction: {
                        sessionManager.poseService.stop()
                        selectedExercise = nil
                        showDebrief = false
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                mainSessionView.transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showDebrief)
        .navigationTitle(selectedExercise?.name ?? "Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.black, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { loadExercises() }
        .onDisappear { sessionManager.poseService.stop() }
        .onChange(of: sessionManager.session.sessionLog.count) {
            if !sessionManager.session.isSetActive && sessionManager.session.sessionLog.count > 0 {
                showDebrief = true
            }
        }
    }

    // MARK: - Main session view

    private var mainSessionView: some View {
        ZStack(alignment: .bottom) {
            CameraView(poseService: sessionManager.poseService,
                       errorJoints: sessionManager.currentErrorJoints)
                .ignoresSafeArea()

            if selectedExercise != nil {
                VStack { activeHUD.padding(.top, 8); Spacer() }
            }

            VStack {
                HStack { Spacer(); aiProcessingBadge.padding(.top, 12).padding(.trailing, 16) }
                Spacer()
            }

            if let flash = errorFlash {
                errorBanner(text: flash)
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
                    .padding(.bottom, selectedExercise == nil ? 380 : 170)
            }

            bottomPanel
        }
        .onReceive(sessionManager.$lastFormError) { rule in
            guard let rule else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                errorFlash = rule.midRepCue.uppercased()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation { errorFlash = nil }
            }
        }
    }

    // MARK: - AI Badge

    private var aiProcessingBadge: some View {
        HStack(spacing: 6) {
            Circle().fill(DS.lime).frame(width: 7, height: 7)
            Text("AI Analyzing")
                .font(.system(size: 11, weight: .semibold)).foregroundStyle(.white)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(.black.opacity(0.55)).background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    // MARK: - Active HUD

    private var activeHUD: some View {
        HStack(alignment: .center, spacing: 0) {
            hudBlock(
                top: Text("\(sessionManager.session.currentSetNumber)")
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white).contentTransition(.numericText()),
                label: "SET"
            )
            hudVertDivider
            hudBlock(
                top: Text("\(sessionManager.repCount)")
                    .font(.system(size: 56, weight: .heavy, design: .rounded))
                    .foregroundStyle(DS.lime).contentTransition(.numericText()),
                label: "REPS"
            )
            if let ex = selectedExercise {
                hudVertDivider
                hudBlock(
                    top: Text(ex.cameraAngle.rawValue)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white).multilineTextAlignment(.center),
                    label: "ANGLE"
                )
            }
            if let curl = sessionManager.fingerCurl.curlData {
                let avgPIP = (curl.indexPIP + curl.middlePIP) / 2.0
                let gripGood = avgPIP < 120
                hudVertDivider
                hudBlock(
                    top: Image(systemName: gripGood ? "hand.raised.fill" : "hand.raised.slash.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(gripGood ? DS.lime : Color.orange),
                    label: "GRIP"
                )
            }
        }
        .padding(.horizontal, 28).padding(.vertical, 14)
        .background(.ultraThinMaterial).background(Color.black.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.horizontal, 16)
        .shadow(color: .black.opacity(0.5), radius: 12, y: 4)
    }

    private func hudBlock<V: View>(top: V, label: String) -> some View {
        VStack(spacing: 3) {
            top
            Text(label).font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white.opacity(0.50)).tracking(1.8)
        }
        .frame(maxWidth: .infinity)
    }

    private var hudVertDivider: some View {
        Rectangle().fill(.white.opacity(0.22)).frame(width: 1, height: 52)
    }

    // MARK: - Error banner

    private func errorBanner(text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow).font(.callout)
            Text(text).font(.callout.weight(.bold)).foregroundStyle(.white)
        }
        .padding(.horizontal, 22).padding(.vertical, 13)
        .background(Color.red.opacity(0.90)).background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .red.opacity(0.45), radius: 12, y: 4)
    }

    // MARK: - Bottom panel (dark glass)

    private var bottomPanel: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.white.opacity(0.18))
                .frame(width: 36, height: 4)
                .padding(.top, 12).padding(.bottom, 8)

            if selectedExercise == nil {
                exercisePicker
            } else {
                activeSetControls
            }
        }
        .background(
            ZStack {
                DS.surface.opacity(0.97)
                Color.clear.background(.ultraThinMaterial)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.5), radius: 28, x: 0, y: -10)
    }

    // MARK: - Exercise Picker

    private var exercisePicker: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Choose exercise")
                        .font(.title3.weight(.bold)).foregroundStyle(DS.textPrimary)
                    Text("\(filteredExercises.count) exercise\(filteredExercises.count == 1 ? "" : "s")")
                        .font(.caption).foregroundStyle(DS.textSecondary)
                }
                Spacer()
                Image(systemName: "magnifyingglass")
                    .font(.body.weight(.medium))
                    .foregroundStyle(DS.textSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 14)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    categoryPill(nil, label: "All", icon: "square.grid.2x2.fill")
                    ForEach(Self.allCategories, id: \.self) { cat in
                        categoryPill(cat, label: cat.rawValue.capitalized,
                                     icon: categoryIcon(cat))
                    }
                }
                .padding(.horizontal, 20).padding(.vertical, 2)
            }
            .padding(.bottom, 14)

            ScrollView(showsIndicators: false) {
                if filteredExercises.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "figure.walk").font(.system(size: 36))
                            .foregroundStyle(DS.textSecondary)
                        Text("No exercises found")
                            .font(.callout).foregroundStyle(DS.textSecondary)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 40)
                } else {
                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 12),
                                  GridItem(.flexible(), spacing: 12)],
                        spacing: 12
                    ) {
                        ForEach(filteredExercises) { exercise in
                            Button {
                                selectedExercise = exercise
                                sessionManager.startSet(exercise: exercise)
                            } label: {
                                exerciseGridCard(exercise)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 4)
                }
            }
            .frame(maxHeight: 320)
            .padding(.bottom, 28)
        }
    }

    private func categoryPill(_ cat: Exercise.Category?, label: String, icon: String) -> some View {
        let selected = selectedCategory == cat
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { selectedCategory = cat }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(label)
                    .font(.callout.weight(selected ? .semibold : .medium))
            }
            .padding(.horizontal, 14).padding(.vertical, 9)
            .background(selected ? DS.lime : DS.elevated)
            .foregroundStyle(selected ? Color.black : DS.textPrimary)
            .clipShape(Capsule())
            .animation(.easeInOut(duration: 0.15), value: selected)
        }
        .buttonStyle(.plain)
    }

    private func exerciseGridCard(_ exercise: Exercise) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                ZStack {
                    RoundedRectangle(cornerRadius: DS.radiusSm, style: .continuous)
                        .fill(categoryColor(exercise.category).opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: categoryIcon(exercise.category))
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(categoryColor(exercise.category))
                }
                Spacer(minLength: 4)
                Text(exercise.category.rawValue.capitalized)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(categoryColor(exercise.category))
                    .clipShape(Capsule())
            }

            Text(exercise.name)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(DS.textPrimary)
                .lineLimit(2).fixedSize(horizontal: false, vertical: true)

            Text(exercise.musclesTargeted.prefix(2).joined(separator: " · "))
                .font(.caption).foregroundStyle(DS.textSecondary).lineLimit(1)

            Spacer(minLength: 0)

            HStack(spacing: 4) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 8)).foregroundStyle(DS.textTertiary)
                Text(exercise.cameraAngle.rawValue)
                    .font(.system(size: 11)).foregroundStyle(DS.textTertiary)
            }
            .padding(.horizontal, 7).padding(.vertical, 4)
            .background(DS.elevated)
            .clipShape(Capsule())
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 148, alignment: .leading)
        .background(DS.surface)
        .clipShape(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous)
                .stroke(DS.elevated, lineWidth: 1)
        )
    }

    // MARK: - Active set controls

    private var activeSetControls: some View {
        VStack(spacing: 14) {
            if let placement = selectedExercise?.phonePlacementInstruction {
                HStack(spacing: 8) {
                    Image(systemName: "iphone.gen3").font(.caption).foregroundStyle(DS.lime)
                    Text(placement).font(.caption).foregroundStyle(DS.textSecondary)
                    Spacer()
                }
                .padding(.horizontal, 20)
            }

            Button {
                sessionManager.poseService.stop()
                sessionManager.endSet()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "stop.circle.fill").font(.title3)
                    Text("End Set").font(.system(size: 18, weight: .bold))
                }
                .dsAccentButton()
                .shadow(color: DS.lime.opacity(0.30), radius: 10, y: 4)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20).padding(.bottom, 36)
        }
    }

    // MARK: - Helpers

    private func categoryColor(_ cat: Exercise.Category) -> Color {
        switch cat {
        case .compound:  return .blue
        case .isolation: return .purple
        case .shoulder:  return .orange
        case .cable:     return .teal
        case .cardio:    return .red
        }
    }

    private func categoryIcon(_ cat: Exercise.Category) -> String {
        switch cat {
        case .compound:  return "figure.strengthtraining.traditional"
        case .isolation: return "figure.arms.open"
        case .shoulder:  return "figure.cooldown"
        case .cable:     return "figure.strengthtraining.functional"
        case .cardio:    return "figure.run"
        }
    }

    private func loadExercises() {
        guard let url = Bundle.main.url(forResource: "Exercises", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Exercise].self, from: data) else { return }
        exercises = decoded
        if let name = initialExerciseName,
           let match = decoded.first(where: { $0.name == name }) {
            selectedExercise = match
            sessionManager.startSet(exercise: match)
        }
    }
}
