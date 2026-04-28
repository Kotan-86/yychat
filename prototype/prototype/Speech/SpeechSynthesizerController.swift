import AVFoundation
import OSLog


// 音声合成と再生を行うクラス
final class SpeechSynthesizerController {
    private let synthesizer = AVSpeechSynthesizer()
    private let logger = Logger(subsystem: "yysystem.prototype", category: "SpeechSynthesizerController")

    init() {
        synthesizer.usesApplicationAudioSession = true
    }

    func speak(text: String) throws {
        logger.debug("speak requested: textLength=\(text.count)")
        try AudioSessionConfigurator.configureAudioSession()
        try AudioSessionConfigurator.activateSession()

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        synthesizer.speak(utterance)
        logger.info("speak started")
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}

