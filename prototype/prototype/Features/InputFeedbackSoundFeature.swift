import Combine
import OSLog

final class InputFeedbackSoundFeature: InputScreenFeaturePlugin {
    private let audioEffectPlayer: AudioEffectPlayer
    private var cancellables: Set<AnyCancellable> = []
    private let logger = Logger(subsystem: "yysystem.prototype", category: "InputFeedbackSoundFeature")
    /// `speechReadMode` の最新値（購読と `events` の sink で共有）。
    private var latestSpeechReadMode: InputSpeechReadMode = .readsConfirmedText

    init(audioEffectPlayer: AudioEffectPlayer) {
        self.audioEffectPlayer = audioEffectPlayer
    }

    func bind(to viewModel: InputScreenViewModel) {
        logger.info("bind completed")
        latestSpeechReadMode = viewModel.speechReadMode.value

        viewModel.speechReadMode
            .removeDuplicates()
            .sink { [weak self] mode in
                self?.latestSpeechReadMode = mode
            }
            .store(in: &cancellables)

        viewModel.events
            .sink { [weak self] event in
                guard let self else { return }
                guard self.latestSpeechReadMode == .readsConfirmedText else {
                    self.logger.debug("skip feedback sound: mode is character-by-character")
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
