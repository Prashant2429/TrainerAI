import SwiftUI

// MARK: - HomeView

struct HomeView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @AppStorage("userName") private var userName = ""
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @State private var showingProfile = false

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
                        statsRow.padding(.horizontal, 20)
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
                    showingProfile = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        hasCompletedOnboarding = false
                    }
                }
            )
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

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 10) {
            statCard(value: "—", label: "Sessions", icon: "flame.fill")
            statCard(value: "—", label: "This week", icon: "calendar")
            statCard(value: "—", label: "Best streak", icon: "bolt.fill")
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

// MARK: - ProfileSheetView

struct ProfileSheetView: View {
    let userName: String
    let onResetOnboarding: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showResetConfirm = false

    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

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
                        showResetConfirm = true
                    } label: {
                        Label("Edit Profile", systemImage: "pencil.circle.fill")
                            .foregroundStyle(.primary)
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
                    LabeledContent("AI Engine", value: "Claude + Pose Detection")
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
