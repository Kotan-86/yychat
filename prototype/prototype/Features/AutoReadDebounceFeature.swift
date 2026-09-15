// 仕様: docs/spec/speech-support-sdk.md#4-方式aの振る舞いsdk-が保証する
import Combine
import Foundation
import OSLog

/// 方式Aのデバウンス確定読み。読み上げ開始成功時は spoken／クリア要求のみ通知し、下書き・タイムラインは触らない。
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

        // 仕様: docs/spec/speech-support-sdk.md#受入基準
        viewModel.events
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
            .debounce(for: .seconds(debounceInterval), scheduler: DispatchQueue.main)
            .sink { [weak self] text in
                guard let self else { return }
                self.logger.debug("debounce fired: textLength=\(text.count)")
                do {
                    try speech.speak(text: text)
                    self.logger.info("auto read speak succeeded")
                    // 仕様: docs/spec/speech-support-sdk.md#3-ホストが受け取る結果
                    self.viewModel?.notifySpoken(text)
                    self.viewModel?.requestClearText()
                } catch {
                    // 仕様: docs/spec/speech-support-sdk.md#4-方式aの振る舞いsdk-が保証する
                    self.logger.error("auto read speak failed: \(error.localizedDescription, privacy: .public)")
                }
            }
            .store(in: &cancellables)
    }
}
