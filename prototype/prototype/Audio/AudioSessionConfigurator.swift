// 仕様: docs/spec/timeline-screen.md

import AVFoundation

// 音声セッションを設定するクラス（受信支援の録音と発言支援の再生を同一セッションで扱う）
final class AudioSessionConfigurator {
    private static var audioSession: AVAudioSession { AVAudioSession.sharedInstance() }

    static func configureAudioSession() throws {
        try audioSession.setCategory(
            .playAndRecord,
            mode: .default,
            options: [.defaultToSpeaker, .allowBluetoothHFP]
        )
    }

    static func activateSession() throws {
        try audioSession.setActive(true)
    }

    /// `setCategory` と `setActive(true)` を連続して1試行として実行する。
    static func activationAttempt() throws {
        try configureAudioSession()
        try activateSession()
    }
}
