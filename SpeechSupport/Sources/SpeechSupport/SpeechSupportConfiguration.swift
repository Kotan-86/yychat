import Foundation

// 仕様: docs/spec/speech-support-sdk.md#2-ホストが渡す入力事実
/// 効果音の役割単位差し替え。未指定の役割は同梱の既定音を使う。
public struct SoundEffectOverrides: Sendable {
    public var hitURL: URL?
    public var deleteURL: URL?

    public init(hitURL: URL? = nil, deleteURL: URL? = nil) {
        self.hitURL = hitURL
        self.deleteURL = deleteURL
    }
}

// 仕様: docs/spec/speech-support-sdk.md#5-セッションと配線
public struct SpeechSupportConfiguration: Sendable {
    public var soundEffectOverrides: SoundEffectOverrides

    public init(soundEffectOverrides: SoundEffectOverrides = SoundEffectOverrides()) {
        self.soundEffectOverrides = soundEffectOverrides
    }
}
