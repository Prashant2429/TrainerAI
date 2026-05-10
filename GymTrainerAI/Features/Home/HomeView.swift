import SwiftUI
import SwiftData
import Foundation

// MARK: - HomeView

struct HomeView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @AppStorage("userName") private var userName = ""
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @State private var showingProfile = false
    @Query(sort: \WorkoutRecord.date, order: .reverse) private var workoutRecords: [WorkoutRecord]
    @Query(sort: \WorkoutPlan.createdAt, order: .reverse) private var plans: [WorkoutPlan]
    private var currentPlan: WorkoutPlan? { plans.first }

    private var totalSessions: Int { workoutRecords.count }

    private var sessionsThisWeek: Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return workoutRecords.filter { $0.date >= cutoff }.count
    }

    private var bestStreak: Int {
        let cal = Calendar.current
        let days = Set(workoutRecords.map { cal.startOfDay(for: $0.date) }).sorted()
        var best = 0, current = 0
        for (i, day) in days.enumerated() {
            if i == 0 {
                current = 1
            } else if cal.dateComponents([.day], from: days[i - 1], to: day).day == 1 {
                current += 1
            } else {
                current = 1
            }
            best = max(best, current)
        }
        return best
    }

    private var daysSinceLastSession: Int? {
        guard let last = workoutRecords.first else { return nil }
        return Calendar.current.dateComponents([.day], from: last.date, to: Date()).day
    }

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Good morning" }
        else if h < 17 { return "Good afternoon" }
        else { return "Good evening" }
    }

    private var displayName: String { userName.isEmpty ? "Athlete" : userName }

    var body: some View {
        NavigationStack {
            ZStack {
                DS.bg.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        headerSection.padding(.top, 16)
                        startWorkoutButton.padding(.horizontal, 20)
                        lastSessionNudge
                        askTrainerCard.padding(.horizontal, 20)
                        statsRow.padding(.horizontal, 20)
                        myPlanCard.padding(.horizontal, 20)
                        quickExercisesSection
                    }
                    .padding(.bottom, 48)
                }
            }
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingProfile) {
            ProfileSheetView(
                userName: displayName,
                onResetOnboarding: {

                    sessionManager.resetForLogout()

                    showingProfile = false

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        hasCompletedOnboarding = false
                    }
                }
            )
            .environmentObject(sessionManager)
            .preferredColorScheme(.dark)
        }  
    }

    // MARK: - Header (dark, large bold type)

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.callout).foregroundStyle(DS.textSecondary)
                Text(displayName)
                    .font(.system(size: 36, weight: .heavy))
                    .foregroundStyle(DS.textPrimary)
            }
            Spacer()
            Button { showingProfile = true } label: {
                ZStack {
                    Circle().fill(DS.surface).frame(width: 46, height: 46)
                    Image(systemName: "person.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(DS.textSecondary)
                }
            }
        }
        .padding(.horizontal, 22)
    }

    // MARK: - Start Workout Button (solid lime)

    private var startWorkoutButton: some View {
        NavigationLink(destination: WorkoutView()) {
            ZStack {
                DS.lime
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 7) {
                        HStack(spacing: 6) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 11, weight: .bold))
                            Text("AI FORM COACH")
                                .font(.system(size: 11, weight: .bold)).tracking(1.2)
                        }
                        .foregroundStyle(Color.black.opacity(0.55))
                        Text("Start Workout")
                            .font(.system(size: 30, weight: .heavy))
                            .foregroundStyle(Color.black)
                        Text("Live pose detection  ·  Voice cues")
                            .font(.caption).foregroundStyle(Color.black.opacity(0.50))
                    }
                    Spacer(minLength: 16)
                    ZStack {
                        Circle().fill(Color.black.opacity(0.12)).frame(width: 68, height: 68)
                        Image(systemName: "play.fill")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(Color.black).offset(x: 3)
                    }
                }
                .padding(.horizontal, 26).padding(.vertical, 24)
            }
            .frame(maxWidth: .infinity).frame(minHeight: 110)
            .clipShape(RoundedRectangle(cornerRadius: DS.radiusLg, style: .continuous))
            .shadow(color: DS.lime.opacity(0.38), radius: 20, x: 0, y: 10)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Last session nudge

    @ViewBuilder
    private var lastSessionNudge: some View {
        if let days = daysSinceLastSession, days >= 2 {
            HStack(spacing: 6) {
                Image(systemName: "clock").font(.caption2).foregroundStyle(DS.textTertiary)
                Text("Last session: \(days) day\(days == 1 ? "" : "s") ago")
                    .font(.caption).foregroundStyle(DS.textTertiary)
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Stats Row

    @ViewBuilder
    private var statsRow: some View {
        if totalSessions == 0 {
            HStack(spacing: 12) {
                Image(systemName: "trophy.fill")
                    .font(.title3).foregroundStyle(DS.lime)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Your stats will appear here")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(DS.textPrimary)
                    Text("Complete your first workout to start tracking")
                        .font(.caption).foregroundStyle(DS.textSecondary)
                }
                Spacer()
            }
            .padding(16)
            .background(DS.surface)
            .clipShape(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous)
                .stroke(DS.elevated, lineWidth: 1))
        } else {
            HStack(spacing: 10) {
                statCard(value: "\(totalSessions)", label: "Sessions", icon: "flame.fill")
                statCard(value: "\(sessionsThisWeek)", label: "This week", icon: "calendar")
                statCard(value: "\(bestStreak)", label: "Best streak", icon: "bolt.fill")
            }
        }
    }

    private func statCard(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 7) {
            Image(systemName: icon).font(.callout).foregroundStyle(DS.lime)
            Text(value).font(.title2.weight(.bold)).foregroundStyle(DS.textPrimary)
            Text(label).font(.caption2).foregroundStyle(DS.textSecondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 18)
        .background(DS.surface)
        .clipShape(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous))
    }

    // MARK: - Ask trainer card

    private var askTrainerCard: some View {
        NavigationLink(destination: CoachChatView()) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(DS.lime.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 20)).foregroundStyle(DS.lime)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Ask your trainer")
                        .font(.subheadline.weight(.bold)).foregroundStyle(DS.textPrimary)
                    Text("Nutrition, recovery, form — anything")
                        .font(.caption).foregroundStyle(DS.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold)).foregroundStyle(DS.textTertiary)
            }
            .padding(16)
            .background(DS.surface)
            .clipShape(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous)
                .stroke(DS.elevated, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - My Plan card

    @ViewBuilder
    private var myPlanCard: some View {
        if let plan = currentPlan {
            let todayName = Calendar.current.weekdaySymbols[
                Calendar.current.component(.weekday, from: Date()) - 1]
            let todayDay = plan.weeklyDays.first { $0.day.lowercased() == todayName.lowercased() }

            NavigationLink(destination: PlanView()) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(DS.lime.opacity(0.15))
                            .frame(width: 48, height: 48)
                        Image(systemName: "list.bullet.clipboard.fill")
                            .font(.system(size: 20)).foregroundStyle(DS.lime)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("My Plan")
                            .font(.subheadline.weight(.bold)).foregroundStyle(DS.textPrimary)
                        if let today = todayDay {
                            Text("Today: \(today.focus) · \(today.exercises.count) exercises")
                                .font(.caption).foregroundStyle(DS.textSecondary)
                        } else {
                            Text("\(plan.weeklyDays.count) training days · \(plan.coachNote.prefix(40))...")
                                .font(.caption).foregroundStyle(DS.textSecondary).lineLimit(1)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold)).foregroundStyle(DS.textTertiary)
                }
                .padding(16)
                .background(DS.surface)
                .clipShape(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous)
                    .stroke(DS.elevated, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Quick Exercises (deep-linked)

    private var quickExercisesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick start")
                .font(.headline).foregroundStyle(DS.textPrimary).padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    quickExCard(name: "Squat",    sf: "figure.squat")
                    quickExCard(name: "Push-up",  sf: "figure.pushup")
                    quickExCard(name: "Deadlift", sf: "figure.strengthtraining.functional")
                    quickExCard(name: "Lunge",    sf: "figure.walk")
                    quickExCard(name: "Plank",    sf: "figure.core.training")
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private func quickExCard(name: String, sf: String) -> some View {
        NavigationLink(destination: WorkoutView(initialExerciseName: name)) {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(DS.lime.opacity(0.14))
                        .frame(width: 56, height: 56)
                    Image(systemName: sf).font(.system(size: 24)).foregroundStyle(DS.lime)
                }
                Text(name).font(.caption.weight(.semibold)).foregroundStyle(DS.textPrimary)
            }
            .frame(width: 82).padding(.vertical, 14)
            .background(DS.surface)
            .clipShape(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - APIKeyEntryView

struct APIKeyEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var keyInput = ""
    @State private var saved = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enter your AI API key. It is stored securely in the iOS Keychain — never in the app bundle.")
                        .font(.callout)
                        .foregroundStyle(DS.textSecondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("API KEY")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(DS.textTertiary)
                        .tracking(0.8)
                    SecureField("sk-ant-api03-…", text: $keyInput)
                        .textFieldStyle(.plain)
                        .foregroundStyle(DS.textPrimary)
                        .tint(DS.lime)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding(12)
                        .background(DS.elevated)
                        .clipShape(RoundedRectangle(cornerRadius: DS.radiusSm, style: .continuous))
                }

                Button {
                    let trimmed = keyInput.trimmingCharacters(in: .whitespaces)
                    if trimmed.isEmpty {
                        KeychainService.delete("AI_API_KEY")
                    } else {
                        KeychainService.save("AI_API_KEY", value: trimmed)
                    }
                    saved = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { dismiss() }
                } label: {
                    HStack(spacing: 8) {
                        if saved {
                            Image(systemName: "checkmark").font(.callout.weight(.semibold))
                            Text("Saved").font(.headline)
                        } else {
                            Text("Save Key").font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 17)
                    .background(saved ? DS.lime.opacity(0.7) : DS.lime)
                    .foregroundStyle(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous))
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.2), value: saved)

                Spacer()
            }
            .padding(24)
            .background(DS.bg.ignoresSafeArea())
            .navigationTitle("AI API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }.fontWeight(.semibold)
                }
            }
            .onAppear {
                keyInput = KeychainService.load("AI_API_KEY") ?? ""
            }
        }
    }
}

// MARK: - ProfileSheetView

struct ProfileSheetView: View {
    let userName: String
    let onResetOnboarding: () -> Void
    @Environment(\.dismiss) private var dismiss
    @AppStorage("userName") private var savedName = ""
    @State private var showResetConfirm = false
    @State private var showAPIKeyEntry = false
    @State private var showEditName = false
    @State private var editNameInput = ""

    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private var apiKeyStatus: String {
        guard let key = KeychainService.load("AI_API_KEY"), !key.isEmpty else { return "Not set" }
        return "••••••••···" + key.suffix(4)
     }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle().fill(DS.lime).frame(width: 64, height: 64)
                            Text(String(userName.prefix(1)).uppercased())
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(Color.black)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(userName).font(.title3.weight(.semibold))
                            Text("GymTrainer AI Member").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Profile") {
                    Button {
                        editNameInput = savedName
                        showEditName = true
                    } label: {
                        Label("Edit Name", systemImage: "pencil.circle.fill")
                            .foregroundStyle(.primary)
                    }
                }

                Section("AI Settings") {
                    Button {
                        showAPIKeyEntry = true
                    } label: {
                        HStack {
                            Label("AI API Key", systemImage: "key.fill")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(apiKeyStatus)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Account") {
                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        Label("Sign Out / Reset Onboarding", systemImage: "arrow.backward.circle.fill")
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: appVersion)
                    LabeledContent("AI Engine", value: "\(UserDefaults.standard.string(forKey: "AI_PROVIDER")?.capitalized ?? "Anthropic") + \" + Pose Detection\"")
                    LabeledContent("Form Analysis", value: "Real-time")
                }
            }
            .navigationTitle("Profile & Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showAPIKeyEntry) {
                APIKeyEntryView()
                    .preferredColorScheme(.dark)
            }
            .sheet(isPresented: $showEditName) {
                NavigationStack {
                    Form {
                        Section("Display Name") {
                            TextField("Your name", text: $editNameInput)
                                .autocorrectionDisabled()
                        }
                    }
                    .navigationTitle("Edit Name")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Cancel") { showEditName = false }
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Save") {
                                let trimmed = editNameInput.trimmingCharacters(in: .whitespaces)
                                if !trimmed.isEmpty { savedName = trimmed }
                                showEditName = false
                            }
                            .fontWeight(.semibold)
                            .disabled(editNameInput.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                }
                .preferredColorScheme(.dark)
            }
            .confirmationDialog(
                "Reset Onboarding?",
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Reset & Sign Out", role: .destructive) { onResetOnboarding() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You'll be taken back to the welcome screen to set up your profile again.")
            }
        }
    }
}

