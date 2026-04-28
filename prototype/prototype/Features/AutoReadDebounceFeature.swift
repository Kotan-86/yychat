import Combine
import Foundation
import OSLog

final class AutoReadDebounceFeature: InputScreenFeaturePlugin {
    private let speech: SpeechSynthesizerController
    private weak var viewModel: InputScreenViewModel?
    private var cancellables: Set<AnyCancellable> = []
    private let debounceInterval: TimeInterval
    private let logger = Logger(subsystem: "yysystem.prototype", category: "AutoReadDebounceFeature")

    init(speech: SpeechSynthesizerController, debounceInterval: TimeInterval = 0.5) {
        self.speech = speech
        self.debounceInterval = debounceInterval
    }

    func bind(to viewModel: InputScreenViewModel) {
        self.viewModel = viewModel
        logger.info("bind completed. debounceInterval=\(self.debounceInterval, format: .fixed(precision: 1))s")

        let confirmedTextStream = viewModel.events
            .compactMap { [weak self] event -> String? in
                guard case let .userChangedConfirmedText(text) = event else { return nil }
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    self?.logger.debug("skip debounce target: trimmed text is empty")
                    return nil
                }
                self?.logger.debug("debounce target accepted: textLength=\(trimmed.count)")
                return trimmed
            }

        confirmedTextStream
            .combineLatest(viewModel.speechReadMode)
            .compactMap { [weak self] text, mode -> String? in
                guard mode == .readsConfirmedText else {
                    self?.logger.debug("skip debounce target: mode is not readsConfirmedText")
                    return nil
                }
                return text
            }
            .debounce(for: .seconds(debounceInterval), scheduler: DispatchQueue.main)
            .sink { [weak self] text in
                guard let self else { return }
                self.logger.debug("debounce fired: textLength=\(text.count)")
                do {
                    try speech.speak(text: text)
                    self.logger.info("auto read speak succeeded")
                    self.viewModel?.clearText()
                } catch {
                    self.logger.error("auto read speak failed: \(error.localizedDescription, privacy: .public)")
                }
            }
            .store(in: &cancellables)
    }
}
