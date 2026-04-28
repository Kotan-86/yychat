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

        let features: [InputScreenFeaturePlugin] = [
            ReadAloudOnReturnFeature(speech: speechController),
            AutoReadDebounceFeature(speech: speechController),
            InputFeedbackSoundFeature(audioEffectPlayer: audioEffectPlayer)
        ]

        features.forEach { $0.bind(to: viewModel) }
        viewController.viewModel = viewModel
        logger.info("compose finished: featureCount=\(features.count)")

        self.viewModel = viewModel
        self.features = features
    }
}
