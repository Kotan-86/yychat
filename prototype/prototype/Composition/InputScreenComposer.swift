import Combine
import OSLog

final class InputScreenComposer {
    private var features: [InputScreenFeaturePlugin] = []
    private var viewModel: InputScreenViewModel?
    private let logger = Logger(subsystem: "yysystem.prototype", category: "InputScreenComposer")

    func compose(into viewController: ViewController) {
        logger.info("compose started")
        let viewModel = InputScreenViewModel()
        let speechController = SpeechSynthesizerController()
        let audioEffectPlayer = AudioEffectPlayer()
        speechController.onSpeakingStateChanged = { isSpeaking in
            viewModel.isSpeaking.send(isSpeaking)
        }
        // 仕様: docs/spec/timeline-screen.md#送信
        // ReadAloudOnReturnFeature は仕様外（Return 時再読み上げなし）のため除外
        let features: [InputScreenFeaturePlugin] = [
            AutoReadDebounceFeature(speech: speechController),
            DraftAccumulatorFeature(),
            InputFeedbackSoundFeature(audioEffectPlayer: audioEffectPlayer)
        ]

        features.forEach { $0.bind(to: viewModel) }
        viewController.viewModel = viewModel
        logger.info("compose finished: featureCount=\(features.count)")

        self.viewModel = viewModel
        self.features = features
    }
}
