import Combine
import Foundation
import OSLog

// 仕様: docs/spec/timeline-screen.md
// 仕様: docs/spec/speech-support-sdk.md#3-ホストが受け取る結果
final class InputScreenViewModel {
    let events = PassthroughSubject<TextAreaInputEvent, Never>()
    let displayState = CurrentValueSubject<TextAreaDisplayState, Never>(TextAreaDisplayState(text: ""))
    // 採用: 現在モードを「状態」として保持するため CurrentValueSubject を使う。
    // 理由: UI/Feature が購読開始した時点で、直近のモード値を即時取得できるため。
    // 不採用: PassthroughSubject<InputSpeechReadMode, Never>
    // 理由: 初期値を保持しないので、購読タイミング次第で現在モードを取りこぼす。
    // 不採用: Bool（例: isCharacterByCharacter）
    // 理由: モード増加時に分岐が壊れやすく、OCPの拡張性が下がる。
    // 注: 製品配線は方式Aのみ。方式B切替 UI／Feature は製品経路に含めない。
    let speechReadMode = CurrentValueSubject<InputSpeechReadMode, Never>(.readsConfirmedText)

    // 仕様: docs/spec/timeline-screen.md#タイムライン表示
    let timelineMessages = CurrentValueSubject<[TimelineMessage], Never>([])
    // 仕様: docs/spec/timeline-screen.md#下書き領域
    let draftText = CurrentValueSubject<String, Never>("")
    // 仕様: docs/spec/speech-support-sdk.md#3-ホストが受け取る結果
    // 音声合成の再生中状態。再生中は音声認識へのマイク送信を一時停止するために利用。
    let isSpeaking = CurrentValueSubject<Bool, Never>(false)

    /// デバウンス確定読みが開始できたときの読み上げ対象文字列（spoken）。ホストが下書き等へ反映する。
    // 仕様: docs/spec/speech-support-sdk.md#3-ホストが受け取る結果
    let spokenText = PassthroughSubject<String, Never>()
    /// 入力欄を空にしてほしい旨。ホストが自画面の入力をクリアする。
    // 仕様: docs/spec/speech-support-sdk.md#3-ホストが受け取る結果
    let clearTextRequest = PassthroughSubject<Void, Never>()

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

    /// Return／送信相当の入力事実。方式Aの既定発言支援では再読み上げに使わない。
    // 仕様: docs/spec/speech-support-sdk.md#2-ホストが渡す入力事実
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
    // ホストが spoken 通知を受けて呼ぶ
    func appendDraft(_ text: String) {
        let current = draftText.value
        let next = current.isEmpty ? text : current + " " + text
        draftText.send(next)
        logger.debug("appendDraft: draftLength=\(next.count)")
    }

    /// 発言支援側が読み上げ開始成功時に呼ぶ。ホストは `spokenText` を購読して反映する。
    // 仕様: docs/spec/speech-support-sdk.md#3-ホストが受け取る結果
    func notifySpoken(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        logger.info("notifySpoken: textLength=\(trimmed.count)")
        spokenText.send(trimmed)
    }

    /// 発言支援側がクリア要求を出すときに呼ぶ。ホストは `clearTextRequest` を購読して入力を空にする。
    // 仕様: docs/spec/speech-support-sdk.md#3-ホストが受け取る結果
    func requestClearText() {
        logger.debug("requestClearText")
        clearTextRequest.send(())
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
    // 注: 製品配線は方式A固定。方式Bへの切替は製品経路に含めない。
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
