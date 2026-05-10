import Foundation
import SwiftUI

struct AIConfig {
    let name: String
    let endpoint: String
    let apiKey: String
    let model: String
    let headers: [String: String]
    let isAnthropic: Bool
}

enum AIProviderType {
    case anthropic
    case aimlapi
    case nvidia
    case groq
}

class AIService: ObservableObject {

    // MARK: - Provider Selection

    private var currentProvider: AIProviderType {
        switch UserDefaults.standard.string(forKey: "AI_PROVIDER") ?? "groq" {
        case "anthropic": return .anthropic
        case "aimlapi":   return .aimlapi
        case "nvidia":    return .nvidia
        default:          return .groq
        }
    }

    private func config() -> AIConfig {
        let key = KeychainService.load("AI_API_KEY") ?? ""
        switch currentProvider {
        case .anthropic:
            return AIConfig(
                name: "Claude",
                endpoint: "https://api.anthropic.com/v1/messages",
                apiKey: key,
                model: "claude-sonnet-4-6",
                headers: [
                    "x-api-key": key,
                    "anthropic-version": "2023-06-01"
                ],
                isAnthropic: true
            )
        case .aimlapi:
            return AIConfig(
                name: "AIMLAPI",
                endpoint: "https://api.aimlapi.com/v1/chat/completions",
                apiKey: key,
                model: "gpt-4o",
                headers: ["Authorization": "Bearer \(key)"],
                isAnthropic: false
            )
        case .nvidia:
            return AIConfig(
                name: "NVIDIA",
                endpoint: "https://integrate.api.nvidia.com/v1/chat/completions",
                apiKey: key,
                model: "meta/llama-3.1-8b-instruct",
                headers: ["Authorization": "Bearer \(key)"],
                isAnthropic: false
            )
        case .groq:
            return AIConfig(
                name: "Groq",
                endpoint: "https://api.groq.com/openai/v1/chat/completions",
                apiKey: key,
                model: "llama-3.3-70b-versatile",
                headers: ["Authorization": "Bearer \(key)"],
                isAnthropic: false
            )
        }
    }

    // MARK: - System Prompt

    private let systemPrompt = """
    You are an expert personal trainer coaching someone through a workout in real time.

    Response length rules (STRICT):
    - Mid-rep cue (during a set): 2–4 words, imperative only. Examples: "knees out", "chest up", "squeeze harder", "slow down".
    - Post-set debrief: 1–2 sentences. Reference the specific error and the rep count. Sound like a real trainer, not a chatbot.
    - Answering a question: 2–3 sentences max. Be direct and specific.

    Coaching rules:
    - Never give generic praise like "great job" or "keep it up" unless form was truly clean — then say exactly what was good.
    - Always tie feedback to what the athlete actually did — reference the error, rep number, or set number when possible.
    - When form breaks down late in a set, name fatigue as the likely cause and suggest a fix (e.g. drop weight, fewer reps).
    - Prioritise safety. If a form issue could cause injury, say so directly.
    """

    // MARK: - Workout Plan

    func generatePlan(profile: UserProfile) async -> WorkoutPlanDTO? {

        let cfg = config()

        guard !cfg.apiKey.isEmpty else {
            print("API key missing")
            return nil
        }

        let prompt = """
        Create a \(profile.availableDaysPerWeek)-day workout plan for a \(profile.age)-year-old \(profile.gender.rawValue).

        Fitness level: \(profile.fitnessLevel.rawValue)
        Equipment: \(profile.hasEquipment.rawValue)

        Goals:
        \(profile.goals.map(\.rawValue).joined(separator: ", "))

        Respond ONLY with valid JSON:

        {
          "weeklyPlan": [
            {
              "day": "Monday",
              "focus": "Push",
              "exercises": [
                {
                  "exerciseId": "bench_press",
                  "sets": 3,
                  "reps": "8-10",
                  "rest": 90
                }
              ]
            }
          ],
          "coachNote": "One sentence."
        }

        Use only:
        squat, deadlift, bench_press, ohp, barbell_row,
        bicep_curl, lateral_raise, cable_pushdown,
        cable_row, lunge
        """

        let body: [String: Any]

        if cfg.isAnthropic {

            body = [
                "model": cfg.model,
                "max_tokens": 1500,
                "system": "You respond only with JSON.",
                "messages": [
                    [
                        "role": "user",
                        "content": prompt
                    ]
                ]
            ]

        } else {

            body = [
                "model": cfg.model,
                "messages": [
                    [
                        "role": "system",
                        "content": "You respond only with JSON."
                    ],
                    [
                        "role": "user",
                        "content": prompt
                    ]
                ],
                "temperature": 0.7
            ]
        }

        guard let data = try? JSONSerialization.data(withJSONObject: body) else {
            return nil
        }

        var request = URLRequest(url: URL(string: cfg.endpoint)!)
        request.httpMethod = "POST"
        request.httpBody = data

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        for (key, value) in cfg.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        do {

            let (responseData, _) = try await URLSession.shared.data(for: request)

            guard let json = try JSONSerialization.jsonObject(with: responseData) as? [String: Any] else {
                return nil
            }

            let text: String?

            if cfg.isAnthropic {
                let content = json["content"] as? [[String: Any]]
                text = content?.first?["text"] as? String
            } else {
                let choices = json["choices"] as? [[String: Any]]
                let message = choices?.first?["message"] as? [String: Any]
                text = message?["content"] as? String
            }

            guard let text else {
                print(json)
                return nil
            }

            let jsonText = extractJSON(text)

            return try? JSONDecoder().decode(
                WorkoutPlanDTO.self,
                from: Data(jsonText.utf8)
            )

        } catch {

            print(error.localizedDescription)
            return nil
        }
    }

    // MARK: - Chat

    func ask(
        userMessage: String,
        conversationHistory: [[String: String]]
    ) async -> String {

        await send(
            userMessage: userMessage,
            conversationHistory: conversationHistory,
            system: systemPrompt
        )
    }

    func askCoach(
        userMessage: String,
        conversationHistory: [[String: String]],
        system: String
    ) async -> String {

        await send(
            userMessage: userMessage,
            conversationHistory: conversationHistory,
            system: system
        )
    }

    // MARK: - Core Send

    private func send(
        userMessage: String,
        conversationHistory: [[String: String]],
        system: String
    ) async -> String {

        let cfg = config()

        guard !cfg.apiKey.isEmpty else {
            return "API key missing."
        }

        var messages = conversationHistory

        messages.append([
            "role": "user",
            "content": userMessage
        ])

        let body: [String: Any]

        if cfg.isAnthropic {

            body = [
                "model": cfg.model,
                "max_tokens": 1000,
                "system": system,
                "messages": messages
            ]

        } else {

            var openAIMessages: [[String: String]] = [
                [
                    "role": "system",
                    "content": system
                ]
            ]

            openAIMessages.append(contentsOf: messages)

            body = [
                "model": cfg.model,
                "messages": openAIMessages,
                "temperature": 0.7
            ]
        }

        guard let data = try? JSONSerialization.data(withJSONObject: body) else {
            return "Failed creating request."
        }

        var request = URLRequest(url: URL(string: cfg.endpoint)!)
        request.httpMethod = "POST"
        request.httpBody = data

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        for (key, value) in cfg.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        do {

            let (responseData, _) = try await URLSession.shared.data(for: request)

            guard let json = try JSONSerialization.jsonObject(with: responseData) as? [String: Any] else {
                return "Invalid response."
            }

            if let error = json["error"] as? [String: Any] {
                return error["message"] as? String ?? "Unknown API error."
            }

            if cfg.isAnthropic {
                let content = json["content"] as? [[String: Any]]
                let text = content?.first?["text"] as? String

                return text ?? "No response."

            } else {

                let choices = json["choices"] as? [[String: Any]]
                let message = choices?.first?["message"] as? [String: Any]
                let text = message?["content"] as? String

                return text ?? "No response."
            }

        } catch {

            return "Error: \(error.localizedDescription)"
        }
    }

    // MARK: - JSON Extractor

    private func extractJSON(_ text: String) -> String {

        if let start = text.range(of: "```json\n"),
           let end = text.range(
                of: "\n```",
                range: start.upperBound..<text.endIndex
           ) {

            return String(text[start.upperBound..<end.lowerBound])
        }

        if let start = text.firstIndex(of: "{"),
           let end = text.lastIndex(of: "}") {

            return String(text[start...end])
        }

        return text
    }
}
