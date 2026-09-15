// 仕様: docs/spec/speech-support-sdk.md#5-セッションと配線
import Combine
import OSLog
import SpeechSupport

/// プロトタイプを SpeechSupport の公開 API 消費者として配線する。
final class InputScreenComposer {
    private var speechSupport: SpeechSupportSession?
    private var viewModel: InputScreenViewModel?
    private var hostCancellables: Set<AnyCancellable> = []
    private let logger = Logger(subsystem: "yysystem.prototype", category: "InputScreenComposer")

    func compose(into viewController: ViewController) {
        logger.info("compose started")
        let speechSupport = SpeechSupportSession()
        let viewModel = InputScreenViewModel()

        // 仕様: docs/spec/speech-support-sdk.md#3-ホストが受け取る結果
        // 仕様: docs/spec/timeline-screen.md#下書き領域
        bindHostSpeechSupportResults(session: speechSupport, viewModel: viewModel)

        viewController.speechSupport = speechSupport
        viewController.viewModel = viewModel
        logger.info("compose finished")

        self.speechSupport = speechSupport
        self.viewModel = viewModel
    }

    /// ホスト側: spoken／クリア要求を下書き・入力クリアへ反映する（SDK は UI を更新しない）。
    private func bindHostSpeechSupportResults(
        session: SpeechSupportSession,
        viewModel: InputScreenViewModel
    ) {
        session.spokenText
            .sink { [weak viewModel] text in
                viewModel?.appendDraft(text)
            }
            .store(in: &hostCancellables)

        session.clearTextRequest
            .sink { [weak viewModel] in
                viewModel?.clearInputText()
            }
            .store(in: &hostCancellables)

        session.isSpeaking
            .sink { [weak viewModel] isSpeaking in
                viewModel?.isSpeaking.send(isSpeaking)
            }
            .store(in: &hostCancellables)
    }
}
