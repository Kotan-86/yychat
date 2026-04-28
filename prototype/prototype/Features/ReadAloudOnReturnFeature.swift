import Combine
import OSLog

final class ReadAloudOnReturnFeature: InputScreenFeaturePlugin {
    private let speech: SpeechSynthesizerController
    private weak var viewModel: InputScreenViewModel?
    private var cancellables: Set<AnyCancellable> = []
    private let logger = Logger(subsystem: "yysystem.prototype", category: "ReadAloudOnReturnFeature")

    init(speech: SpeechSynthesizerController) {
        self.speech = speech
    }

    func bind(to viewModel: InputScreenViewModel) {
        self.viewModel = viewModel
        logger.info("bind completed")

        viewModel.events
            .sink { [weak self] event in
                guard let self else { return }
                guard case let .userPressedReturnKey(text) = event else { return }
                self.logger.debug("return read requested: textLength=\(text.count)")

                do {
                    try speech.speak(text: text)
                    self.logger.info("return read speak succeeded")
                    self.viewModel?.clearText()
                } catch {
                    self.logger.error("return read speak failed: \(error.localizedDescription, privacy: .public)")
                }
            }
            .store(in: &cancellables)
    }
}
