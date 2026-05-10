import Foundation
import AVFoundation
import Speech

class VoiceCoachService: NSObject, ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    @Published var isListening = false
    @Published var partialTranscript = ""

    func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { _ in }
    }

    // MARK: - Output (TTS)

    func speakMidRepCue(_ cue: String) { speak(cue, rate: 0.55, volume: 1.0) }
    func speakDebrief(_ message: String) { speak(message, rate: 0.48, volume: 0.9) }
    func stopSpeaking() { synthesizer.stopSpeaking(at: .immediate) }

    private func speak(_ text: String, rate: Float, volume: Float) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate
        utterance.volume = volume
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }

    // MARK: - Input (STT)

    func startListening(completion: @escaping (String) -> Void) {
        guard !audioEngine.isRunning, speechRecognizer?.isAvailable == true else { return }

        synthesizer.stopSpeaking(at: .immediate)

        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playAndRecord, mode: .measurement,
                options: [.defaultToSpeaker, .mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { return }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            if let result {
                let text = result.bestTranscription.formattedString
                DispatchQueue.main.async { self?.partialTranscript = text }
                if result.isFinal {
                    if !text.isEmpty { completion(text) }
                    self?.cleanup()
                }
            }
            if let error {
                let code = (error as NSError).code
                if code != 301 { self?.cleanup() }  // 301 = cancelled by user, ignore
            }
        }

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try? audioEngine.start()
        DispatchQueue.main.async { self.isListening = true }
    }

    func stopListening() {
        guard audioEngine.isRunning else { return }
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()  // triggers isFinal in the task callback
    }

    private func cleanup() {
        recognitionRequest = nil
        recognitionTask = nil
        DispatchQueue.main.async {
            self.isListening = false
            self.partialTranscript = ""
        }
    }
}
