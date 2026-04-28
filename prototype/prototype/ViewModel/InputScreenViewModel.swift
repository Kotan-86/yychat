import Combine
import Foundation
import OSLog

final class InputScreenViewModel {
    let events = PassthroughSubject<TextAreaInputEvent, Never>()
    let displayState = CurrentValueSubject<TextAreaDisplayState, Never>(TextAreaDisplayState(text: ""))

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

    func clearText() {
        logger.debug("clearText called")
        previousText = ""
        previousIsComposing = false
        displayState.send(TextAreaDisplayState(text: ""))
    }
}
