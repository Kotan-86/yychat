import AVFoundation


// 音声セッションを設定するクラス
final class AudioSessionConfigurator {
    private static var audioSession: AVAudioSession { AVAudioSession.sharedInstance() }
    
    static func configureAudioSession() throws {
        try audioSession.setCategory(.playback, mode: .default)
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
