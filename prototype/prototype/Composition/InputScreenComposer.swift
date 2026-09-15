// 仕様: docs/spec/speech-support-sdk.md#5-セッションと配線
import Combine
import OSLog

/// プロトタイプ内の発言支援配線。製品経路は方式Aのみ（方式B・Return 再読み上げは除外）。
final class InputScreenComposer {
    private var features: [InputScreenFeaturePlugin] = []
    private var viewModel: InputScreenViewModel?
    private var hostCancellables: Set<AnyCancellable> = []
    private let logger = Logger(subsystem: "yysystem.prototype", category: "InputScreenComposer")

    func compose(into viewController: ViewController) {
        logger.info("compose started")
        let viewModel = InputScreenViewModel()
        let speechController = SpeechSynthesizerController()
        let audioEffectPlayer = AudioEffectPlayer()
        speechController.onSpeakingStateChanged = { isSpeaking in
            viewModel.isSpeaking.send(isSpeaking)
        }

        // 仕様: docs/spec/speech-support-sdk.md#7-含めないもの
        // DraftAccumulatorFeature / CharByCharReadFeature / ReadAloudOnReturnFeature は製品配線に含めない
        let features: [InputScreenFeaturePlugin] = [
            AutoReadDebounceFeature(speech: speechController),
            InputFeedbackSoundFeature(audioEffectPlayer: audioEffectPlayer)
        ]

        features.forEach { $0.bind(to: viewModel) }
        bindHostSpeechSupportResults(to: viewModel)
        viewController.viewModel = viewModel
        logger.info("compose finished: featureCount=\(features.count)")

        self.viewModel = viewModel
        self.features = features
    }

    /// ホスト側: spoken／クリア要求を下書き・入力クリアへ反映する（SDK は UI を更新しない）。
    // 仕様: docs/spec/speech-support-sdk.md#3-ホストが受け取る結果
    // 仕様: docs/spec/timeline-screen.md#下書き領域
    private func bindHostSpeechSupportResults(to viewModel: InputScreenViewModel) {
        viewModel.spokenText
            .sink { [weak viewModel] text in
                viewModel?.appendDraft(text)
            }
            .store(in: &hostCancellables)

        viewModel.clearTextRequest
            .sink { [weak viewModel] in
                viewModel?.clearText()
            }
            .store(in: &hostCancellables)
    }
}
