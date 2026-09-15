// 仕様: docs/spec/speech-support-sdk.md#4-方式aの振る舞いsdk-が保証する
import Combine
import OSLog

/// 方式Aの変換中効果音。読み上げ中は抑制する。
final class InputFeedbackSoundFeature: SpeechSupportFeaturePlugin {
    private let audioEffectPlayer: AudioEffectPlayer
    private var cancellables: Set<AnyCancellable> = []
    private let logger = Logger(subsystem: "SpeechSupport", category: "InputFeedbackSoundFeature")
    private var latestIsSpeaking: Bool = false

    init(audioEffectPlayer: AudioEffectPlayer) {
        self.audioEffectPlayer = audioEffectPlayer
    }

    func bind(to engine: SpeechSupportEngine) {
        logger.info("bind completed")
        latestIsSpeaking = engine.isSpeaking.value

        engine.isSpeaking
            .removeDuplicates()
            .sink { [weak self] isSpeaking in
                self?.latestIsSpeaking = isSpeaking
            }
            .store(in: &cancellables)

        // 仕様: docs/spec/speech-support-sdk.md#受入基準
        engine.events
            .sink { [weak self] event in
                guard let self else { return }
                guard self.latestIsSpeaking == false else {
                    self.logger.debug("skip feedback sound: speaking")
                    return
                }
                switch event {
                case .userTypedComposingCharacter:
                    audioEffectPlayer.playHit()
                case .userDeletedComposingCharacter:
                    audioEffectPlayer.playDelete()
                case .userChangedConfirmedText, .userPressedReturnKey:
                    break
                }
            }
            .store(in: &cancellables)
    }
}
