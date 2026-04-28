import Combine
import Foundation
import OSLog

final class InputScreenViewModel {
    let events = PassthroughSubject<TextAreaInputEvent, Never>()
    let displayState = CurrentValueSubject<TextAreaDisplayState, Never>(TextAreaDisplayState(text: ""))
    // 採用: 現在モードを「状態」として保持するため CurrentValueSubject を使う。
    // 理由: UI/Feature が購読開始した時点で、直近のモード値を即時取得できるため。
    // 不採用: PassthroughSubject<InputSpeechReadMode, Never>
    // 理由: 初期値を保持しないので、購読タイミング次第で現在モードを取りこぼす。
    // 不採用: Bool（例: isCharacterByCharacter）
    // 理由: モード増加時に分岐が壊れやすく、OCPの拡張性が下がる。
    let speechReadMode = CurrentValueSubject<InputSpeechReadMode, Never>(.readsConfirmedText)

    private var previousText: String = ""
    private var previousIsComposing: Bool = false
    private let logger = Logger(subsystem: "yysystem.prototype", category: "InputScreenViewModel")

    func onTextAreaTextDidChange(currentText: String, isComposing: Bool) {
        displayState.send(TextAreaDisplayState(text: currentText))
        logger.debug("onTextAreaTextDidChange: currentLength=\(currentText.count), previousLength=\(self.previousText.count), isComposing=\(isComposing), previousIsComposing=\(self.previousIsComposing)")
        if isComposing {
            guard currentText != previousText else {
                previousIsComposing = isComposing
                return
            }
            if currentText.count > previousText.count {
                logger.debug("event emitted: userTypedComposingCharacter")
                events.send(.userTypedComposingCharacter(text: currentText))
            } else if currentText.count < previousText.count {
                logger.debug("event emitted: userDeletedComposingCharacter")
                events.send(.userDeletedComposingCharacter(text: currentText))
            }
        } else {
            logger.debug("event emitted: userChangedConfirmedText")
            events.send(.userChangedConfirmedText(text: currentText))
        }

        previousText = currentText
        previousIsComposing = isComposing
    }

    func onTextAreaReturnKeyDidPress(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else {
            logger.debug("return ignored: trimmed text is empty")
            return
        }
        logger.debug("event emitted: userPressedReturnKey, textLength=\(trimmed.count)")
        events.send(.userPressedReturnKey(text: trimmed))
    }

    // 採用: View はこのメソッド呼び出しだけを行い、モード変更の表現を ViewModel に集約する。
    // 不採用: View から speechReadMode.send(...) を直接呼ぶ
    // 理由: View が Combine 実装詳細を知ることになり、MVVMの責務分離が崩れる。
    func selectSpeechReadMode(_ mode: InputSpeechReadMode) {
        logger.info("speechReadMode will change: from=\(String(describing: self.speechReadMode.value), privacy: .public) to=\(String(describing: mode), privacy: .public)")
        speechReadMode.send(mode)
        logger.info("speechReadMode did change: current=\(String(describing: self.speechReadMode.value), privacy: .public)")
    }

    func clearText() {
        logger.debug("clearText called")
        previousText = ""
        previousIsComposing = false
        displayState.send(TextAreaDisplayState(text: ""))
    }
}
