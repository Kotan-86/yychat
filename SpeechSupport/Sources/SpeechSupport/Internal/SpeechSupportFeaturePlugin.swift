/// 内部 Feature プラグイン。ホスト必須契約にしない。
// 仕様: docs/spec/speech-support-sdk.md#7-含めないもの
protocol SpeechSupportFeaturePlugin: AnyObject {
    func bind(to engine: SpeechSupportEngine)
}
