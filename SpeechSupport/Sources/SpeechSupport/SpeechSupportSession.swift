import Combine
import Foundation
import OSLog

// 仕様: docs/spec/speech-support-sdk.md#5-セッションと配線
/// 方式A発言支援のホスト向けセッション。入力事実を渡し、結果を購読する。
public final class SpeechSupportSession {
    private let engine: SpeechSupportEngine
    private let features: [any SpeechSupportFeaturePlugin]
    private let speech: any TextToSpeechEngine
    private let logger = Logger(subsystem: "SpeechSupport", category: "SpeechSupportSession")

    /// 読み上げ対象になった文字列（spoken）。ホストが下書き等へ反映する。
    // 仕様: docs/spec/speech-support-sdk.md#3-ホストが受け取る結果
    public var spokenText: AnyPublisher<String, Never> {
        engine.spokenText.eraseToAnyPublisher()
    }

    /// 入力欄を空にしてほしい旨。ホストが自画面の入力をクリアする。
    // 仕様: docs/spec/speech-support-sdk.md#3-ホストが受け取る結果
    public var clearTextRequest: AnyPublisher<Void, Never> {
        engine.clearTextRequest.eraseToAnyPublisher()
    }

    /// 読み上げ再生中かどうか。ホストが認識のストップ／再開に使う。
    // 仕様: docs/spec/speech-support-sdk.md#3-ホストが受け取る結果
    public var isSpeaking: AnyPublisher<Bool, Never> {
        engine.isSpeaking.eraseToAnyPublisher()
    }

    /// 読み上げ中の現在値（購読開始前の同期参照用）。
    public var isSpeakingValue: Bool {
        engine.isSpeaking.value
    }

    // 仕様: docs/spec/speech-support-sdk.md#5-セッションと配線
    public convenience init(configuration: SpeechSupportConfiguration = SpeechSupportConfiguration()) {
        let speech = SpeechSynthesizerController()
        let audioEffectPlayer = AudioEffectPlayer(overrides: configuration.soundEffectOverrides)
        self.init(
            speech: speech,
            audioEffectPlayer: audioEffectPlayer,
            debounceInterval: 0.5
        )
    }

    /// テスト／差し替え用。公開契約ではなくパッケージ内の検証入口。
    init(
        speech: any TextToSpeechEngine,
        audioEffectPlayer: AudioEffectPlayer,
        debounceInterval: TimeInterval
    ) {
        let engine = SpeechSupportEngine()
        speech.onSpeakingStateChanged = { isSpeaking in
            engine.isSpeaking.send(isSpeaking)
        }

        // 仕様: docs/spec/speech-support-sdk.md#7-含めないもの
        // 方式B・Return 再読み上げ Feature は製品配線に含めない
        let features: [any SpeechSupportFeaturePlugin] = [
            AutoReadDebounceFeature(speech: speech, debounceInterval: debounceInterval),
            InputFeedbackSoundFeature(audioEffectPlayer: audioEffectPlayer)
        ]
        features.forEach { $0.bind(to: engine) }

        self.engine = engine
        self.features = features
        self.speech = speech
        logger.info("session ready: featureCount=\(features.count)")
    }

    /// 現在テキスト＋IME 未確定かを渡す。分類は SDK 内で行う。
    // 仕様: docs/spec/speech-support-sdk.md#2-ホストが渡す入力事実
    public func notifyTextDidChange(currentText: String, isComposing: Bool) {
        engine.notifyTextDidChange(currentText: currentText, isComposing: isComposing)
    }

    /// Return／送信相当。方式Aの既定発言支援では再読み上げに使わない。
    // 仕様: docs/spec/speech-support-sdk.md#2-ホストが渡す入力事実
    // 仕様: docs/spec/speech-support-sdk.md#7-含めないもの
    public func notifyReturnOrSendPressed(text: String) {
        engine.notifyReturnOrSendPressed(text: text)
    }
}
