import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("userName") private var savedName = ""
    @State private var profile = UserProfile.empty

    var body: some View {
        ZStack {
            DS.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Brand
                    VStack(spacing: 14) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 64))
                            .foregroundStyle(DS.lime)
                            .padding(.top, 70)

                        Text("GymTrainer AI")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(DS.textPrimary)

                        Text("Your personal AI form coach")
                            .font(.callout)
                            .foregroundStyle(DS.textSecondary)
                    }
                    .padding(.bottom, 44)

                    // Form fields
                    VStack(alignment: .leading, spacing: 22) {
                        Text("Tell us about yourself")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(DS.textPrimary)

                        formField(label: "Your name") {
                            TextField("Enter your name", text: $profile.name)
                                .textFieldStyle(.plain)
                                .foregroundStyle(DS.textPrimary)
                                .tint(DS.lime)
                                .padding(12)
                                .background(DS.elevated)
                                .clipShape(RoundedRectangle(cornerRadius: DS.radiusSm, style: .continuous))
                        }

                        HStack(spacing: 16) {
                            formField(label: "Age") {
                                HStack {
                                    Text("\(profile.age) yrs")
                                        .font(.callout)
                                        .foregroundStyle(DS.textPrimary)
                                        .frame(minWidth: 54, alignment: .leading)
                                    Stepper("", value: $profile.age, in: 13...80)
                                        .labelsHidden()
                                        .tint(DS.lime)
                                }
                                .padding(12)
                                .background(DS.elevated)
                                .clipShape(RoundedRectangle(cornerRadius: DS.radiusSm, style: .continuous))
                            }
                            .frame(maxWidth: .infinity)

                            formField(label: "Gender") {
                                Picker("", selection: $profile.gender) {
                                    ForEach(UserProfile.Gender.allCases, id: \.self) { g in
                                        Text(g.rawValue.capitalized).tag(g)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(DS.lime)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(DS.elevated)
                                .clipShape(RoundedRectangle(cornerRadius: DS.radiusSm, style: .continuous))
                            }
                            .frame(maxWidth: .infinity)
                        }

                        formField(label: "Fitness level") {
                            HStack(spacing: 8) {
                                ForEach(UserProfile.FitnessLevel.allCases, id: \.self) { level in
                                    let selected = profile.fitnessLevel == level
                                    Button {
                                        profile.fitnessLevel = level
                                    } label: {
                                        Text(level.rawValue.capitalized)
                                            .font(.callout)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 9)
                                            .frame(maxWidth: .infinity)
                                            .background(selected ? DS.lime : DS.elevated)
                                            .foregroundStyle(selected ? Color.black : DS.textPrimary)
                                            .clipShape(RoundedRectangle(cornerRadius: DS.radiusSm, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                    .animation(.easeInOut(duration: 0.15), value: profile.fitnessLevel)
                                }
                            }
                        }

                        formField(label: "Days per week") {
                            HStack(spacing: 6) {
                                ForEach(1...7, id: \.self) { day in
                                    let selected = profile.availableDaysPerWeek == day
                                    Button {
                                        profile.availableDaysPerWeek = day
                                    } label: {
                                        Text("\(day)")
                                            .font(.callout.weight(.medium))
                                            .foregroundStyle(selected ? Color.black : DS.textPrimary)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 38)
                                            .background(selected ? DS.lime : DS.elevated)
                                            .clipShape(RoundedRectangle(cornerRadius: DS.radiusSm, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                    .animation(.easeInOut(duration: 0.15), value: profile.availableDaysPerWeek)
                                }
                            }
                        }

                        formField(label: "Equipment access") {
                            Picker("", selection: $profile.hasEquipment) {
                                ForEach(UserProfile.EquipmentAccess.allCases, id: \.self) { e in
                                    Text(e.rawValue).tag(e)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(DS.lime)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(DS.elevated)
                            .clipShape(RoundedRectangle(cornerRadius: DS.radiusSm, style: .continuous))
                        }

                        // CTA
                        Button {
                            savedName = profile.name
                            hasCompletedOnboarding = true
                        } label: {
                            HStack(spacing: 8) {
                                Text("Get Started").font(.headline)
                                Image(systemName: "arrow.right").font(.callout.weight(.semibold))
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 17)
                            .background(profile.name.isEmpty ? DS.lime.opacity(0.3) : DS.lime)
                            .foregroundStyle(profile.name.isEmpty ? Color.black.opacity(0.4) : Color.black)
                            .clipShape(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous))
                        }
                        .disabled(profile.name.isEmpty)
                        .padding(.top, 4)
                    }
                    .padding(24)

                    Spacer().frame(height: 48)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func formField<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(DS.textTertiary)
                .tracking(0.8)
            content()
        }
    }
}
