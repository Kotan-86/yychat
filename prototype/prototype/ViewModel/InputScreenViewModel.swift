import Combine
import Foundation
import OSLog

// 仕様: docs/spec/timeline-screen.md
/// ホスト（プロトタイプ）専用の画面状態。発言支援ロジックは `SpeechSupport` 公開 API 側。
final class InputScreenViewModel {
    /// 入力欄の表示テキスト（ホストが所有。クリア要求に応じて空にする）。
    let inputText = CurrentValueSubject<String, Never>("")
    // 仕様: docs/spec/timeline-screen.md#タイムライン表示
    let timelineMessages = CurrentValueSubject<[TimelineMessage], Never>([])
    // 仕様: docs/spec/timeline-screen.md#下書き領域
    let draftText = CurrentValueSubject<String, Never>("")
    // 仕様: docs/spec/speech-support-sdk.md#3-ホストが受け取る結果
    // SpeechSupportSession.isSpeaking をミラーし、認識一時停止に使う。
    let isSpeaking = CurrentValueSubject<Bool, Never>(false)

    private let logger = Logger(subsystem: "yysystem.prototype", category: "InputScreenViewModel")

    // 仕様: docs/spec/timeline-screen.md#送信
    // 入力欄が空かつ下書きに内容がある場合のみタイムラインに追加する
    func onReturnKeyDidPress() {
        let input = inputText.value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard input.isEmpty else {
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
        clearInputText()
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

    /// クリア要求または送信後に入力欄表示を空にする。
    // 仕様: docs/spec/speech-support-sdk.md#3-ホストが受け取る結果
    func clearInputText() {
        inputText.send("")
        logger.debug("clearInputText")
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
}
