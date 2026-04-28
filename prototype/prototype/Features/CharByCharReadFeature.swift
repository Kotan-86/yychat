import Combine
import OSLog

final class CharByCharReadFeature: InputScreenFeaturePlugin {
    private let speech: SpeechSynthesizerController
    private var cancellables: Set<AnyCancellable> = []
    private var previousComposingText: String = ""
    private var consecutiveDeleteCount: Int = 0
    private let logger = Logger(subsystem: "yysystem.prototype", category: "CharByCharReadFeature")

    init(speech: SpeechSynthesizerController) {
        self.speech = speech
    }

    func bind(to viewModel: InputScreenViewModel) {
        logger.info("bind completed")

        viewModel.speechReadMode
            .removeDuplicates()
            .sink { [weak self] mode in
                guard let self else { return }
                guard mode == .readsCharacterByCharacter else {
                    // 採用: モード離脱時に内部状態を初期化して、再入時の誤発話を防ぐ。
                    // 不採用: 状態を保持し続ける案。理由: モード再選択直後に過去の削除回数を引きずるため。
                    self.resetTransientState()
                    return
                }
            }
            .store(in: &cancellables)

        viewModel.events
            .sink { [weak self] event in
                guard let self else { return }
                guard viewModel.speechReadMode.value == .readsCharacterByCharacter else { return }
                self.handle(event: event)
            }
            .store(in: &cancellables)
    }

    private func handle(event: TextAreaInputEvent) {
        switch event {
        case let .userTypedComposingCharacter(text):
            consecutiveDeleteCount = 0
            speakAddedCharacterIfNeeded(currentText: text)
            previousComposingText = text

        case let .userDeletedComposingCharacter(text):
            consecutiveDeleteCount += 1
            if consecutiveDeleteCount == 2 {
                speak(text: "えー")
            }
            previousComposingText = text

        case let .userChangedConfirmedText(text):
            consecutiveDeleteCount = 0
            previousComposingText = text

        case .userPressedReturnKey:
            consecutiveDeleteCount = 0
            previousComposingText = ""
        }
    }

    private func speakAddedCharacterIfNeeded(currentText: String) {
        guard let character = extractSingleAddedCharacter(previous: previousComposingText, current: currentText) else {
            return
        }
        speak(text: String(character))
    }

    private func extractSingleAddedCharacter(previous: String, current: String) -> Character? {
        guard current.count > previous.count else { return nil }

        let previousChars = Array(previous)
        let currentChars = Array(current)
        var prefixLength = 0
        let minCount = min(previousChars.count, currentChars.count)

        while prefixLength < minCount, previousChars[prefixLength] == currentChars[prefixLength] {
            prefixLength += 1
        }

        guard prefixLength < currentChars.count else { return nil }
        return currentChars[prefixLength]
    }

    private func speak(text: String) {
        do {
            try speech.speak(text: text)
            logger.debug("char-by-char speak succeeded: textLength=\(text.count)")
        } catch {
            logger.error("char-by-char speak failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func resetTransientState() {
        previousComposingText = ""
        consecutiveDeleteCount = 0
    }
}
