import Combine
import Foundation
import OSLog

// 仕様: docs/spec/timeline-screen.md
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

    // 仕様: docs/spec/timeline-screen.md#タイムライン表示
    let timelineMessages = CurrentValueSubject<[TimelineMessage], Never>([])
    // 仕様: docs/spec/timeline-screen.md#下書き領域
    let draftText = CurrentValueSubject<String, Never>("")
    // 仕様: docs/spec/timeline-screen.md#発言支援（方式A）
    // 音声合成の再生中状態。再生中は音声認識へのマイク送信を一時停止するために利用。
    let isSpeaking = CurrentValueSubject<Bool, Never>(false)

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

    // 仕様: docs/spec/timeline-screen.md#送信
    // 入力欄が空かつ下書きに内容がある場合のみタイムラインに追加する
    func onReturnKeyDidPress() {
        let inputText = displayState.value.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard inputText.isEmpty else {
            logger.debug("onReturnKeyDidPress ignored: input text is not empty")
            return
        }
        let draft = draftText.value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !draft.isEmpty else {
            logger.debug("onReturnKeyDidPress ignored: draft is empty")
            return
        }
        let message = TimelineMessage(id: UUID(), direction: .sent, text: draft, status: .final_)
        var messages = timelineMessages.value
        messages.append(message)
        timelineMessages.send(messages)
        draftText.send("")
        clearText()
        logger.info("onReturnKeyDidPress: sent message added, draftLength=\(draft.count)")
    }

    // 仕様: docs/spec/timeline-screen.md#下書き領域
    // DraftAccumulatorFeature から呼ばれる
    func appendDraft(_ text: String) {
        let current = draftText.value
        let next = current.isEmpty ? text : current + " " + text
        draftText.send(next)
        logger.debug("appendDraft: draftLength=\(next.count)")
    }

    // 仕様: docs/spec/timeline-screen.md#タイムライン表示
    // デバウンス読み上げ済みテキストを送信メッセージとしてタイムラインに追加する
    func addSentMessageFromReadAloud(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var messages = timelineMessages.value
        messages.append(TimelineMessage(id: UUID(), direction: .sent, text: trimmed, status: .final_))
        timelineMessages.send(messages)
        logger.info("addSentMessageFromReadAloud: messageLength=\(trimmed.count)")
    }

    // 仕様: docs/spec/timeline-screen.md#受信メッセージ（Phase 5 接続用 stub）
    func addReceivedPartial(id: UUID, text: String) {
        var messages = timelineMessages.value
        messages.append(TimelineMessage(id: id, direction: .received, text: text, status: .partial))
        timelineMessages.send(messages)
    }

    func updateReceivedPartial(id: UUID, text: String) {
        var messages = timelineMessages.value
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
        messages[index].text = text
        timelineMessages.send(messages)
    }

    func finalizeReceived(id: UUID) {
        var messages = timelineMessages.value
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
        messages[index].status = .final_
        timelineMessages.send(messages)
    }

    func removeReceived(id: UUID) {
        var messages = timelineMessages.value
        messages.removeAll { $0.id == id }
        timelineMessages.send(messages)
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
