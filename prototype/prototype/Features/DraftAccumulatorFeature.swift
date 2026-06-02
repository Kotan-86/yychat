// 仕様: docs/spec/timeline-screen.md#下書き領域
import Combine
import Foundation
import OSLog

// AutoReadDebounceFeature と同じ debounce 条件（userChangedConfirmedText + 0.5s）を監視し、
// 読み上げとほぼ同タイミングで appendDraft を呼ぶ。
// clearText() は AutoReadDebounceFeature 側が引き続き担当する。
final class DraftAccumulatorFeature: InputScreenFeaturePlugin {
    private var cancellables: Set<AnyCancellable> = []
    private let debounceInterval: TimeInterval
    private let logger = Logger(subsystem: "yysystem.prototype", category: "DraftAccumulatorFeature")

    init(debounceInterval: TimeInterval = 0.5) {
        self.debounceInterval = debounceInterval
    }

    func bind(to viewModel: InputScreenViewModel) {
        logger.info("bind completed. debounceInterval=\(self.debounceInterval, format: .fixed(precision: 1))s")

        viewModel.events
            .compactMap { event -> String? in
                guard case let .userChangedConfirmedText(text) = event else { return nil }
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : trimmed
            }
            .combineLatest(viewModel.speechReadMode)
            .compactMap { [weak self] text, mode -> String? in
                guard mode == .readsConfirmedText else {
                    self?.logger.debug("skip draft accumulate: mode is not readsConfirmedText")
                    return nil
                }
                return text
            }
            .debounce(for: .seconds(debounceInterval), scheduler: DispatchQueue.main)
            .sink { [weak viewModel, weak self] text in
                guard let self else { return }
                self.logger.debug("debounce fired: appendDraft textLength=\(text.count)")
                viewModel?.appendDraft(text)
            }
            .store(in: &cancellables)
    }
}
