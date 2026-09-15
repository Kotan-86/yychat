// 仕様: docs/spec/speech-support-sdk.md#4-方式aの振る舞いsdk-が保証する
import Combine
import OSLog

/// 方式Aの変換中効果音。読み上げ中は抑制する。方式B切替は製品配線に含めない。
final class InputFeedbackSoundFeature: InputScreenFeaturePlugin {
    private let audioEffectPlayer: AudioEffectPlayer
    private var cancellables: Set<AnyCancellable> = []
    private let logger = Logger(subsystem: "yysystem.prototype", category: "InputFeedbackSoundFeature")
    /// `isSpeaking` の最新値（購読と `events` の sink で共有）。
    private var latestIsSpeaking: Bool = false

    init(audioEffectPlayer: AudioEffectPlayer) {
        self.audioEffectPlayer = audioEffectPlayer
    }

    func bind(to viewModel: InputScreenViewModel) {
        logger.info("bind completed")
        latestIsSpeaking = viewModel.isSpeaking.value

        viewModel.isSpeaking
            .removeDuplicates()
            .sink { [weak self] isSpeaking in
                self?.latestIsSpeaking = isSpeaking
            }
            .store(in: &cancellables)

        // 仕様: docs/spec/speech-support-sdk.md#受入基準
        viewModel.events
            .sink { [weak self] event in
                guard let self else { return }
                guard self.latestIsSpeaking == false else {
                    self.logger.debug("skip feedback sound: speaking")
                    return
                }
                switch event {
                case .userTypedComposingCharacter:
                    self.logger.debug("play hit sound")
                    audioEffectPlayer.playHit()
                case .userDeletedComposingCharacter:
                    self.logger.debug("play delete sound")
                    audioEffectPlayer.playDelete()
                case .userChangedConfirmedText, .userPressedReturnKey:
                    break
                }
            }
            .store(in: &cancellables)
    }
}
