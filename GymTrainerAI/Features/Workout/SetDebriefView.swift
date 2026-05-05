import SwiftUI

struct SetDebriefView: View {
    @EnvironmentObject var sessionManager: SessionManager
    let setLog: WorkoutSession.SetLog
    let nextSetAction: () -> Void
    let endWorkoutAction: () -> Void

    @State private var animateRing = false
    @State private var restSeconds = 60
    @State private var restActive = true
    @State private var restTimer: Timer? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            DS.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerSection.padding(.top, 36)
                    if restActive {
                        restBadge
                            .transition(.opacity.combined(with: .scale(scale: 0.92)))
                    }
                    scoreRing
                    debriefCard.padding(.horizontal, 20)
                    feedbackSection.padding(.horizontal, 20)
                }
                .padding(.bottom, 160)
                .animation(.easeInOut(duration: 0.35), value: restActive)
            }

            actionButtons
        }
        .preferredColorScheme(.dark)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeOut(duration: 0.9)) { animateRing = true }
            }
            startRestTimer()
        }
        .onDisappear { restTimer?.invalidate() }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle().fill(formScoreColor.opacity(0.12)).frame(width: 72, height: 72)
                Image(systemName: formScoreIcon)
                    .font(.system(size: 34)).foregroundStyle(formScoreColor)
            }
            Text("Set \(setLog.setNumber) Complete")
                .font(.title2.weight(.bold)).foregroundStyle(DS.textPrimary)
            HStack(spacing: 6) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.caption).foregroundStyle(DS.textSecondary)
                Text("\(setLog.reps) reps · \(setLog.exercise)")
                    .font(.subheadline).foregroundStyle(DS.textSecondary)
            }
        }
    }

    // MARK: - Rest badge (demoted from full section)

    private var restBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "timer").font(.caption).foregroundStyle(DS.lime)
            Text("\(restSeconds)s rest")
                .font(.system(size: 13, weight: .semibold)).foregroundStyle(DS.textPrimary)
                .contentTransition(.numericText())
            Button("Skip") {
                restTimer?.invalidate()
                withAnimation { restActive = false }
            }
            .font(.system(size: 12)).foregroundStyle(DS.textSecondary)
        }
        .padding(.horizontal, 16).padding(.vertical, 9)
        .background(DS.elevated)
        .clipShape(Capsule())
    }

    // MARK: - Score ring (lime gradient)

    private var scoreRing: some View {
        ZStack {
            Circle().stroke(DS.elevated, lineWidth: 14).frame(width: 144, height: 144)
            Circle()
                .trim(from: 0, to: animateRing ? setLog.formScore : 0)
                .stroke(
                    LinearGradient(
                        colors: [DS.lime, Color(red: 0.2, green: 0.9, blue: 0.4)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 144, height: 144)
            VStack(spacing: 1) {
                Text("\(Int(setLog.formScore * 100))")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(DS.lime)
                    .contentTransition(.numericText())
                Text("FORM %")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(DS.textTertiary).tracking(1.5)
            }
        }
    }

    // MARK: - AI debrief card

    @ViewBuilder
    private var debriefCard: some View {
        let text = sessionManager.lastDebriefText
        if !text.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "brain.head.profile")
                        .font(.caption).foregroundStyle(DS.lime)
                    Text("AI Coach")
                        .font(.caption.weight(.semibold)).foregroundStyle(DS.lime)
                }
                Text(text)
                    .font(.callout).foregroundStyle(DS.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.elevated)
            .overlay(
                RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous)
                    .stroke(DS.lime.opacity(0.22), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous))
        }
    }

    // MARK: - Feedback

    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !setLog.errorsDetected.isEmpty {
                HStack {
                    Label("Coach notes", systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(DS.textSecondary)
                    Spacer()
                    Text("\(setLog.errorsDetected.count) issue\(setLog.errorsDetected.count == 1 ? "" : "s")")
                        .font(.caption).foregroundStyle(.orange)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Color.orange.opacity(0.15)).clipShape(Capsule())
                }

                ForEach(setLog.errorsDetected, id: \.self) { error in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange).font(.callout).padding(.top, 1)
                        Text(error).font(.callout).foregroundStyle(DS.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.radiusSm, style: .continuous)
                            .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: DS.radiusSm, style: .continuous))
                }
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(DS.lime).font(.title3)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Perfect form!").font(.callout.weight(.semibold)).foregroundStyle(DS.textPrimary)
                        Text("Maintain this technique for your next set")
                            .font(.caption).foregroundStyle(DS.textSecondary)
                    }
                    Spacer()
                }
                .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                .background(DS.lime.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous)
                        .stroke(DS.lime.opacity(0.2), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous))
            }
        }
    }

    // MARK: - Action buttons

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button {
                restTimer?.invalidate()
                nextSetAction()
            } label: {
                HStack(spacing: 8) {
                    Text("Next Set").font(.headline)
                    Image(systemName: "arrow.right").font(.callout.weight(.semibold))
                }
                .dsAccentButton()
            }
            .buttonStyle(.plain)

            Button {
                restTimer?.invalidate()
                endWorkoutAction()
            } label: {
                Text("End Workout")
                    .font(.subheadline.weight(.medium))
                    .dsGhostButton()
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 36)
        .background(DS.bg)
    }

    // MARK: - Rest Timer Logic

    private func startRestTimer() {
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            if restSeconds > 0 {
                withAnimation { restSeconds -= 1 }
            } else {
                t.invalidate()
                withAnimation(.easeInOut(duration: 0.4)) { restActive = false }
            }
        }
    }

    // MARK: - Helpers

    private var formScoreColor: Color {
        switch setLog.formScore {
        case 0.8...: return DS.lime
        case 0.5..<0.8: return .orange
        default: return .red
        }
    }

    private var formScoreIcon: String {
        switch setLog.formScore {
        case 0.8...: return "checkmark.seal.fill"
        case 0.5..<0.8: return "exclamationmark.circle.fill"
        default: return "xmark.circle.fill"
        }
    }
}
