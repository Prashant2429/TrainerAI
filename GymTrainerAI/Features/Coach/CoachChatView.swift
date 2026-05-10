import SwiftUI
import SwiftData

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let role: String   // "user" | "assistant"
    let content: String

    init(role: String, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
    }
}

struct CoachChatView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @Query(sort: \WorkoutRecord.date, order: .reverse) private var recentWorkouts: [WorkoutRecord]

    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showClearConfirm = false
    @State private var showAPIKeySheet = false
    @State private var isVoiceListening = false
    @FocusState private var inputFocused: Bool

    private let persistenceKey = "coachChatHistory"

    private var hasAPIKey: Bool {
        guard let key = KeychainService.load("AI_API_KEY") else { return false }
        return !key.isEmpty
    }

    private let suggestions = [
        "Why is my form score dropping?",
        "What should I eat before training?",
        "My lower back is sore — should I deadlift?",
        "Can you adjust this week's plan?"
    ]

    private var showSuggestions: Bool { messages.isEmpty && !isLoading }

    private var workoutContext: String {
        guard !recentWorkouts.isEmpty else { return "" }
        return recentWorkouts.prefix(3).map { r in
            let date = DateFormatter.localizedString(from: r.date, dateStyle: .short, timeStyle: .none)
            let sets = r.sets.prefix(4).map { "\($0.exercise): \($0.reps) reps, \(Int($0.formScore * 100))% form" }.joined(separator: "; ")
            return "\(date): \(sets)"
        }.joined(separator: "\n")
    }

    private var historyForAPI: [[String: String]] {
        messages.map { ["role": $0.role, "content": $0.content] }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            DS.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                if !hasAPIKey {
                    Button { showAPIKeySheet = true } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "key.fill").font(.caption).foregroundStyle(.black)
                            Text("No API key set — tap to configure")
                                .font(.caption.weight(.semibold)).foregroundStyle(.black)
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.black.opacity(0.6))
                        }
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(DS.lime)
                    }
                    .buttonStyle(.plain)
                }

                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 12) {
                            if messages.isEmpty && !isLoading {
                                emptyState.padding(.top, 40)
                            }
                            ForEach(messages) { msg in
                                messageBubble(msg)
                                    .id(msg.id)
                            }
                            if let err = errorMessage {
                                HStack {
                                    Spacer(minLength: 60)
                                    Button { retry() } label: {
                                        Label(err, systemImage: "exclamationmark.circle.fill")
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 12).padding(.vertical, 8)
                                            .background(Color.red.opacity(0.85))
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .id("error")
                            }
                            if isLoading { typingIndicator.id("typing") }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, showSuggestions ? 200 : 100)
                    }
                    .onChange(of: messages.count) {
                        withAnimation { proxy.scrollTo(messages.last?.id, anchor: .bottom) }
                    }
                    .onChange(of: isLoading) {
                        if isLoading { withAnimation { proxy.scrollTo("typing", anchor: .bottom) } }
                    }
                }
            }

            VStack(spacing: 0) {
                if showSuggestions {
                    suggestedPromptsBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                inputBar
            }
            .animation(.easeInOut(duration: 0.2), value: showSuggestions)
        }
        .navigationTitle("AI Coach")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(DS.bg, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { loadHistory() }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showClearConfirm = true } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(messages.isEmpty ? DS.textTertiary : DS.textSecondary)
                }
                .disabled(messages.isEmpty)
            }
        }
        .alert("Clear Chat", isPresented: $showClearConfirm) {
            Button("Clear", role: .destructive) {
                messages = []
                errorMessage = nil
                UserDefaults.standard.removeObject(forKey: persistenceKey)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete the entire chat history.")
        }
        .sheet(isPresented: $showAPIKeySheet) {
            APIKeySetupSheet()
        }
    }

    // MARK: - Bubbles

    private func messageBubble(_ msg: ChatMessage) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            if msg.role == "user" { Spacer(minLength: 60) }

            if msg.role == "assistant" {
                ZStack {
                    Circle().fill(DS.elevated).frame(width: 28, height: 28)
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 12)).foregroundStyle(DS.lime)
                }
                .alignmentGuide(.bottom) { d in d[.bottom] }
            }

            Text(msg.content)
                .font(.callout)
                .foregroundStyle(msg.role == "user" ? Color.black : DS.textPrimary)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(msg.role == "user" ? DS.lime : DS.surface)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(msg.role == "user" ? Color.clear : DS.elevated, lineWidth: 1)
                )

            if msg.role == "assistant" { Spacer(minLength: 60) }
        }
    }

    private var typingIndicator: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle().fill(DS.elevated).frame(width: 28, height: 28)
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 12)).foregroundStyle(DS.lime)
            }
            HStack(spacing: 4) {
                ForEach(0..<3) { i in
                    Circle().fill(DS.textTertiary).frame(width: 7, height: 7)
                        .scaleEffect(isLoading ? 1.2 : 0.8)
                        .animation(.easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.15),
                                   value: isLoading)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(DS.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            Spacer(minLength: 60)
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(DS.lime.opacity(0.12)).frame(width: 72, height: 72)
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 32)).foregroundStyle(DS.lime)
            }
            Text("Your AI Trainer").font(.title3.weight(.bold)).foregroundStyle(DS.textPrimary)
            Text("Ask anything — training, nutrition, recovery, or form tips.")
                .font(.callout).foregroundStyle(DS.textSecondary)
                .multilineTextAlignment(.center).padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Suggested prompts

    private var suggestedPromptsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(suggestions, id: \.self) { prompt in
                    Button { send(prompt) } label: {
                        Text(prompt)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(DS.textPrimary)
                            .padding(.horizontal, 14).padding(.vertical, 9)
                            .background(DS.elevated)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
        }
        .background(DS.bg)
    }

    // MARK: - Input bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            // Voice mic button
            Button {
                if isVoiceListening {
                    sessionManager.voiceCoach.stopListening()
                    isVoiceListening = false
                } else {
                    isVoiceListening = true
                    inputText = ""
                    sessionManager.voiceCoach.startListening { spokenText in
                        isVoiceListening = false
                        send(spokenText)
                    }
                }
            } label: {
                Image(systemName: isVoiceListening ? "waveform" : "mic.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isVoiceListening ? .red : DS.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(isVoiceListening ? Color.red.opacity(0.12) : DS.elevated)
                    .clipShape(Circle())
                    .scaleEffect(isVoiceListening ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true),
                               value: isVoiceListening)
            }
            .buttonStyle(.plain)

            TextField(isVoiceListening ? sessionManager.voiceCoach.partialTranscript.isEmpty
                      ? "Listening…" : sessionManager.voiceCoach.partialTranscript
                      : "Ask your trainer…",
                      text: $inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .foregroundStyle(DS.textPrimary)
                .tint(DS.lime)
                .lineLimit(1...4)
                .focused($inputFocused)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(DS.elevated)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            Button {
                send(inputText)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isLoading
                                     ? DS.lime.opacity(0.3) : DS.lime)
            }
            .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(DS.bg)
        .overlay(Rectangle().fill(DS.elevated).frame(height: 1), alignment: .top)
    }

    // MARK: - Actions

    private func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        inputText = ""
        inputFocused = false
        errorMessage = nil

        let history = historyForAPI
        let context = workoutContext
        messages.append(ChatMessage(role: "user", content: trimmed))
        isLoading = true

        Task { await fetchReply(message: trimmed, history: history, context: context) }
    }

    private func retry() {
        guard let lastUser = messages.last(where: { $0.role == "user" }) else { return }
        errorMessage = nil
        isLoading = true
        let history = messages.dropLast().map { ["role": $0.role, "content": $0.content] }
        let context = workoutContext
        Task { await fetchReply(message: lastUser.content, history: Array(history), context: context) }
    }

    private func fetchReply(message: String, history: [[String: String]], context: String) async {
        let reply = await sessionManager.chatWithCoach(message: message, chatHistory: history, workoutContext: context)
        await MainActor.run {
            isLoading = false
            let knownErrors = ["API key missing", "No response", "Error:", "Invalid response",
                               "Failed creating", "Unknown API", "Couldn't connect"]
            let isError = reply.isEmpty || knownErrors.contains { reply.hasPrefix($0) }
            if isError {
                errorMessage = reply.isEmpty ? "Couldn't connect — try again." : reply
            } else {
                messages.append(ChatMessage(role: "assistant", content: reply))
                saveHistory()
            }
        }
    }

    // MARK: - Persistence

    private func saveHistory() {
        guard let data = try? JSONEncoder().encode(messages) else { return }
        UserDefaults.standard.set(data, forKey: persistenceKey)
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey),
              let saved = try? JSONDecoder().decode([ChatMessage].self, from: data) else { return }
        messages = saved.filter { !$0.content.isEmpty }
    }
}

// MARK: - API Key setup sheet

private struct APIKeySetupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var provider: String = UserDefaults.standard.string(forKey: "AI_PROVIDER") ?? "groq"
    @State private var apiKey: String = KeychainService.load("AI_API_KEY") ?? ""

    var body: some View {
        NavigationStack {
            ZStack {
                DS.bg.ignoresSafeArea()
                VStack(spacing: 20) {
                    Text("Configure AI Provider")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(DS.textPrimary)
                        .padding(.top, 24)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Provider").font(.caption).foregroundStyle(DS.textSecondary)
                        Picker("", selection: $provider) {
                            Text("Groq (free, fast)").tag("groq")
                            Text("Anthropic (Claude)").tag("anthropic")
                            Text("AIMLAPI").tag("aimlapi")
                        }
                        .pickerStyle(.menu)
                        .tint(DS.lime)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(DS.elevated)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .padding(.horizontal, 20)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Key").font(.caption).foregroundStyle(DS.textSecondary)
                        SecureField("Paste your API key", text: $apiKey)
                            .textFieldStyle(.plain)
                            .foregroundStyle(DS.textPrimary)
                            .tint(DS.lime)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .padding(12)
                            .background(DS.elevated)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .padding(.horizontal, 20)

                    Text(providerHint)
                        .font(.caption2)
                        .foregroundStyle(DS.textTertiary)
                        .padding(.horizontal, 20)

                    Button {
                        KeychainService.save("AI_API_KEY", value: apiKey)
                        UserDefaults.standard.set(provider, forKey: "AI_PROVIDER")
                        dismiss()
                    } label: {
                        Text("Save & Connect")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(apiKey.isEmpty ? DS.elevated : DS.lime)
                            .foregroundStyle(apiKey.isEmpty ? DS.textTertiary : .black)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(apiKey.isEmpty)
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(DS.textSecondary)
                }
            }
        }
    }

    private var providerHint: String {
        switch provider {
        case "groq":       return "Get a free key at console.groq.com — model: llama-3.3-70b-versatile"
        case "anthropic":  return "Get a key at console.anthropic.com — model: claude-sonnet-4-6"
        case "aimlapi":    return "Get a key at aimlapi.com"
        default:           return ""
        }
    }
}
