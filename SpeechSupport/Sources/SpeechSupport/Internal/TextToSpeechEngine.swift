/// TTS 再生の内部抽象。Audio Session 設定は行わない。
// 仕様: docs/spec/speech-support-sdk.md#5-セッションと配線
protocol TextToSpeechEngine: AnyObject {
    var onSpeakingStateChanged: ((Bool) -> Void)? { get set }
    func speak(text: String) throws
    func stopSpeaking()
}
