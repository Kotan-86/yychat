import AVFoundation
import CoreFoundation
import OSLog

/// `CharByCharReadFeature` などから、計測ログの文脈を区別するために渡す。
enum SpeechMetricsKind: String, Sendable {
    case composingCharacterAdded = "文字追加（変換中）"
    case consecutiveDeleteFillSound = "連続削除「えー」"
}

// MARK: - Speech synthesizer

final class SpeechSynthesizerController {
    private let synthesizer = AVSpeechSynthesizer()
    private let logger = Logger(subsystem: "yysystem.prototype", category: "SpeechSynthesizerController")

#if DEBUG
    private let speechMetricsTracker = SpeechMetricsTracker()
    private let speechMetricsDelegate = SpeechMetricsDelegate()
#endif

    init() {
        synthesizer.usesApplicationAudioSession = true
#if DEBUG
        speechMetricsDelegate.tracker = speechMetricsTracker
        synthesizer.delegate = speechMetricsDelegate
#endif
    }

    /// - Parameters:
    ///   - metricsInputTime: 非 `nil` かつ `metricsKind` が非 `nil` のときのみ、レイテンシ計測の FIFO に積む。
    ///   - metricsKind: `metricsInputTime` とセットで指定する。
    func speak(
        text: String,
        metricsInputTime: CFAbsoluteTime? = nil,
        metricsKind: SpeechMetricsKind? = nil
    ) throws {
        logger.debug("speak requested: textLength=\(text.count)")

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
#if DEBUG
        if let start = metricsInputTime, let kind = metricsKind {
            speechMetricsTracker.enqueue(
                inputTime: start,
                identifier: text,
                kind: kind
            )
        }
#endif
        synthesizer.speak(utterance)
        logger.info("speak started")
    }

    func stopSpeaking() {
#if DEBUG
        speechMetricsTracker.flushCancelledPending()
#endif
        synthesizer.stopSpeaking(at: .immediate)
    }
}

#if DEBUG

private final class SpeechMetricsDelegate: NSObject, AVSpeechSynthesizerDelegate {
    weak var tracker: SpeechMetricsTracker?

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        assert(Thread.isMainThread)
        tracker?.handleDidStart(utteranceText: utterance.speechString)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        assert(Thread.isMainThread)
        tracker?.handleDidFinish()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        assert(Thread.isMainThread)
        tracker?.handleDidCancel()
    }
}

private final class SpeechMetricsTracker {
    private struct Pending {
        let inputTime: CFAbsoluteTime
        let identifier: String
        let kind: SpeechMetricsKind
    }

    private var pending: [Pending] = []
    private var lastUtteranceStartTime: CFAbsoluteTime?
    private var lastUtteranceFinishTime: CFAbsoluteTime?

    private let logger = Logger(subsystem: "yysystem.prototype", category: "SpeechMetrics")

    func enqueue(inputTime: CFAbsoluteTime, identifier: String, kind: SpeechMetricsKind) {
        assert(Thread.isMainThread)
        pending.append(Pending(inputTime: inputTime, identifier: identifier, kind: kind))
    }

    /// `stopSpeaking` 時など。再生前に棄却されたペンディングをログに出して空にする。
    func flushCancelledPending() {
        assert(Thread.isMainThread)
        for p in pending {
            let line = "\(p.identifier)：発話キャンセル：キュー破棄（\(p.kind.rawValue)）"
            logger.info("\(line, privacy: .public)")
        }
        pending.removeAll()
    }

    func handleDidStart(utteranceText: String) {
        let now = CFAbsoluteTimeGetCurrent()

        if let front = pending.first {
            pending.removeFirst()
            let latencyMs = (now - front.inputTime) * 1000
            let latencyLine = "\(front.identifier)：発話までの遅延：\(millisString(latencyMs))ms"
            logger.info("\(latencyLine, privacy: .public)")
            let contextLine = "音声計測文脈：\(front.kind.rawValue)：\(front.identifier)"
            logger.info("\(contextLine, privacy: .public)")
        }

        if let lastStart = lastUtteranceStartTime {
            let ioiMs = (now - lastStart) * 1000
            let line = "\(utteranceText)：発話開始間隔：\(millisString(ioiMs))ms"
            logger.info("\(line, privacy: .public)")
        }

        if let lastFinish = lastUtteranceFinishTime {
            let gapMs = (now - lastFinish) * 1000
            let line = "\(utteranceText)：無音間隔：\(millisString(gapMs))ms"
            logger.info("\(line, privacy: .public)")
        }

        lastUtteranceStartTime = now
    }

    func handleDidFinish() {
        lastUtteranceFinishTime = CFAbsoluteTimeGetCurrent()
    }

    /// `didCancel` で `didStart` 前に打ち切られた場合、先頭のペンディングを 1 件落とす。
    func handleDidCancel() {
        guard let removed = pending.first else { return }
        pending.removeFirst()
        let line = "\(removed.identifier)：発話キャンセル：didCancel（\(removed.kind.rawValue)）"
        logger.info("\(line, privacy: .public)")
    }
}

private func millisString(_ ms: Double) -> String {
    let rounded = round(ms * 100) / 100
    if rounded == floor(rounded) {
        return String(format: "%.0f", rounded)
    }
    return String(format: "%.2f", rounded)
}
#endif
