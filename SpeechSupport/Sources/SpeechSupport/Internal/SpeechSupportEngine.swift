import Combine
import Foundation
import OSLog

// 仕様: docs/spec/speech-support-sdk.md#5-セッションと配線
/// 入力事実をドメインイベントへ翻訳する内部エンジン。ホストには公開しない。
final class SpeechSupportEngine {
    let events = PassthroughSubject<TextAreaInputEvent, Never>()
    let isSpeaking = CurrentValueSubject<Bool, Never>(false)
    let spokenText = PassthroughSubject<String, Never>()
    let clearTextRequest = PassthroughSubject<Void, Never>()

    private var previousText: String = ""
    private var previousIsComposing: Bool = false
    private let logger = Logger(subsystem: "SpeechSupport", category: "SpeechSupportEngine")

    func notifyTextDidChange(currentText: String, isComposing: Bool) {
        logger.debug("notifyTextDidChange: currentLength=\(currentText.count), previousLength=\(self.previousText.count), isComposing=\(isComposing)")
        if isComposing {
            guard currentText != previousText else {
                previousIsComposing = isComposing
                return
            }
            if currentText.count > previousText.count {
                events.send(.userTypedComposingCharacter(text: currentText))
            } else if currentText.count < previousText.count {
                events.send(.userDeletedComposingCharacter(text: currentText))
            }
        } else {
            events.send(.userChangedConfirmedText(text: currentText))
        }

        previousText = currentText
        previousIsComposing = isComposing
    }

    /// Return／送信相当。方式A製品配線では再読み上げ Feature がいないため副作用はない。
    func notifyReturnOrSendPressed(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return }
        events.send(.userPressedReturnKey(text: trimmed))
    }

    /// 読み上げ開始成功時。ホストは `spokenText` を購読する。
    // 仕様: docs/spec/speech-support-sdk.md#3-ホストが受け取る結果
    func notifySpoken(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        spokenText.send(trimmed)
    }

    /// クリア要求。内部トラッキングもリセットする。ホストが入力欄を空にする。
    // 仕様: docs/spec/speech-support-sdk.md#3-ホストが受け取る結果
    func requestClearText() {
        previousText = ""
        previousIsComposing = false
        clearTextRequest.send(())
    }
}
