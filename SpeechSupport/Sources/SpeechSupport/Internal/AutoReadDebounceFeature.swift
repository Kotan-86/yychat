// 仕様: docs/spec/speech-support-sdk.md#4-方式aの振る舞いsdk-が保証する
import Combine
import Foundation
import OSLog

/// 方式Aのデバウンス確定読み。読み上げ開始成功時は spoken／クリア要求のみ通知する。
final class AutoReadDebounceFeature: SpeechSupportFeaturePlugin {
    private let speech: any TextToSpeechEngine
    private weak var engine: SpeechSupportEngine?
    private var cancellables: Set<AnyCancellable> = []
    private let debounceInterval: TimeInterval
    private let logger = Logger(subsystem: "SpeechSupport", category: "AutoReadDebounceFeature")

    init(speech: any TextToSpeechEngine, debounceInterval: TimeInterval = 0.5) {
        self.speech = speech
        self.debounceInterval = debounceInterval
    }

    func bind(to engine: SpeechSupportEngine) {
        self.engine = engine
        logger.info("bind completed. debounceInterval=\(self.debounceInterval, format: .fixed(precision: 1))s")

        // 仕様: docs/spec/speech-support-sdk.md#受入基準
        // 仕様: docs/spec/bugs/TBD_debounce-clear-still-speaks.md
        // 空／空白もデバウンス入力に含め、待機中候補を取り消す。
        engine.events
            .compactMap { event -> String? in
                guard case let .userChangedConfirmedText(text) = event else { return nil }
                return text.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .debounce(for: .seconds(debounceInterval), scheduler: DispatchQueue.main)
            .sink { [weak self] text in
                guard let self else { return }
                guard text.isEmpty == false else {
                    self.logger.debug("skip auto read: trimmed text is empty after debounce")
                    return
                }
                do {
                    try speech.speak(text: text)
                    self.logger.info("auto read speak succeeded")
                    // 仕様: docs/spec/speech-support-sdk.md#3-ホストが受け取る結果
                    self.engine?.notifySpoken(text)
                    self.engine?.requestClearText()
                } catch {
                    // 仕様: docs/spec/speech-support-sdk.md#4-方式aの振る舞いsdk-が保証する
                    self.logger.error("auto read speak failed: \(error.localizedDescription, privacy: .public)")
                }
            }
            .store(in: &cancellables)
    }
}
