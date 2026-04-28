import Combine
import OSLog

final class InputFeedbackSoundFeature: InputScreenFeaturePlugin {
    private let audioEffectPlayer: AudioEffectPlayer
    private var cancellables: Set<AnyCancellable> = []
    private let logger = Logger(subsystem: "yysystem.prototype", category: "InputFeedbackSoundFeature")

    init(audioEffectPlayer: AudioEffectPlayer) {
        self.audioEffectPlayer = audioEffectPlayer
    }

    func bind(to viewModel: InputScreenViewModel) {
        logger.info("bind completed")
        viewModel.events
            .sink { [weak self] event in
                guard let self else { return }
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
