import SwiftUI
import SwiftData

struct PlanView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutPlan.createdAt, order: .reverse) private var plans: [WorkoutPlan]

    @State private var isRegenerating = false
    @State private var exerciseNames: [String: String] = [:]

    private var plan: WorkoutPlan? { plans.first }

    private var todayName: String {
        Calendar.current.weekdaySymbols[Calendar.current.component(.weekday, from: Date()) - 1]
    }

    private var todayPlan: PlannedDay? {
        plan?.weeklyDays.first { $0.day.lowercased() == todayName.lowercased() }
    }

    var body: some View {
        ZStack {
            DS.bg.ignoresSafeArea()

            if let plan {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        coachNoteCard(plan.coachNote).padding(.horizontal, 20)

                        if let today = todayPlan {
                            todayButton(today).padding(.horizontal, 20)
                        }

                        ForEach(plan.weeklyDays.sorted { $0.day < $1.day }, id: \.persistentModelID) { day in
                            dayCard(day).padding(.horizontal, 20)
                        }

                        regenerateButton.padding(.horizontal, 20).padding(.bottom, 36)
                    }
                    .padding(.top, 16)
                }
            } else {
                emptyState
            }

            if isRegenerating {
                ZStack {
                    DS.bg.opacity(0.92).ignoresSafeArea()
                    VStack(spacing: 20) {
                        ProgressView().tint(DS.lime).scaleEffect(1.4)
                        Text("Regenerating your plan...")
                            .font(.callout.weight(.medium))
                            .foregroundStyle(DS.textSecondary)
                    }
                }
                .transition(.opacity)
            }
        }
        .navigationTitle("My Plan")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(DS.bg, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .animation(.easeInOut(duration: 0.25), value: isRegenerating)
        .onAppear { loadExerciseNames() }
    }

    // MARK: - Coach note

    private func coachNoteCard(_ note: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.callout).foregroundStyle(DS.lime).padding(.top, 2)
            Text(note)
                .font(.callout).foregroundStyle(DS.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.elevated)
        .overlay(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous)
            .stroke(DS.lime.opacity(0.22), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous))
    }

    // MARK: - Today's workout button

    private func todayButton(_ day: PlannedDay) -> some View {
        let firstName = day.exercises.first.flatMap { exerciseNames[$0.exerciseId] }
        return NavigationLink(destination: WorkoutView(initialExerciseName: firstName)) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TODAY · \(day.focus.uppercased())")
                        .font(.system(size: 11, weight: .bold)).tracking(1)
                        .foregroundStyle(Color.black.opacity(0.6))
                    Text("Start \(day.day)'s Workout")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundStyle(Color.black)
                    Text("\(day.exercises.count) exercises")
                        .font(.caption).foregroundStyle(Color.black.opacity(0.55))
                }
                Spacer()
                Image(systemName: "play.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.black)
            }
            .padding(.horizontal, 22).padding(.vertical, 20)
            .background(DS.lime)
            .clipShape(RoundedRectangle(cornerRadius: DS.radiusLg, style: .continuous))
            .shadow(color: DS.lime.opacity(0.35), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Day card

    private func dayCard(_ day: PlannedDay) -> some View {
        let isToday = day.day.lowercased() == todayName.lowercased()
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(day.day)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(isToday ? DS.lime : DS.textPrimary)
                Spacer()
                Text(day.focus)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(isToday ? DS.lime : DS.textSecondary)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(isToday ? DS.lime.opacity(0.15) : DS.elevated)
                    .clipShape(Capsule())
            }

            ForEach(day.exercises, id: \.persistentModelID) { ex in
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(DS.lime.opacity(0.5))
                        .frame(width: 3, height: 32)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exerciseNames[ex.exerciseId] ?? ex.exerciseId.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.callout.weight(.medium))
                            .foregroundStyle(DS.textPrimary)
                        Text("\(ex.sets) sets · \(ex.reps) reps · \(ex.rest)s rest")
                            .font(.caption).foregroundStyle(DS.textSecondary)
                    }
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(DS.surface)
        .clipShape(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous)
                .stroke(isToday ? DS.lime.opacity(0.3) : DS.elevated, lineWidth: 1)
        )
    }

    // MARK: - Regenerate

    private var regenerateButton: some View {
        Button {
            Task { await regeneratePlan() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.clockwise").font(.callout.weight(.semibold))
                Text("Regenerate Plan").font(.subheadline.weight(.medium))
            }
            .dsGhostButton()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 48)).foregroundStyle(DS.textTertiary)
            Text("No plan yet")
                .font(.title3.weight(.semibold)).foregroundStyle(DS.textPrimary)
            Text("Complete onboarding to generate your personalised plan.")
                .font(.callout).foregroundStyle(DS.textSecondary)
                .multilineTextAlignment(.center).padding(.horizontal, 40)
        }
    }

    // MARK: - Helpers

    @MainActor
    private func regeneratePlan() async {
        guard let data = UserDefaults.standard.data(forKey: "userProfile"),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data) else { return }
        isRegenerating = true
        defer { isRegenerating = false }

        guard let dto = await sessionManager.generatePlan(profile: profile) else { return }

        // Delete existing plans
        for old in plans { modelContext.delete(old) }

        let days = dto.weeklyPlan.map { d in
            let exs = d.exercises.map {
                PlannedExercise(exerciseId: $0.exerciseId, sets: $0.sets,
                                reps: $0.reps, rest: $0.rest)
            }
            return PlannedDay(day: d.day, focus: d.focus, exercises: exs)
        }
        let plan = WorkoutPlan(createdAt: Date(), coachNote: dto.coachNote, weeklyDays: days)
        modelContext.insert(plan)
        try? modelContext.save()
    }

    private func loadExerciseNames() {
        guard let url = Bundle.main.url(forResource: "Exercises", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Exercise].self, from: data) else { return }
        exerciseNames = Dictionary(uniqueKeysWithValues: decoded.map { ($0.id, $0.name) })
    }
}
