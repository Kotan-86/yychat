import OSLog
import UIKit

/// 起動時に `AVAudioSession` を最大10回試行で有効化し、試行中はウィンドウ最前面で操作をブロックする。
@MainActor
final class AudioSessionBootstrapController {
    private static let maxAttempts = 10
    private static let retryDelayNanoseconds: UInt64 = 50_000_000 // 50 ms

    private let logger = Logger(subsystem: "yysystem.prototype", category: "AudioSessionBootstrap")

    private weak var window: UIWindow?
    private let overlay: UIView
    private let statusLabel: UILabel

    init(window: UIWindow) {
        self.window = window

        let overlay = UIView(frame: window.bounds)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        overlay.isUserInteractionEnabled = true
        overlay.accessibilityLabel = "初回ロード中"

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "初回ロード中"
        label.textColor = .white
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .title2)
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityTraits = .staticText

        overlay.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -24),
            label.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
        ])

        self.overlay = overlay
        self.statusLabel = label
    }

    func attachOverlayToWindow() {
        guard let window else { return }
        overlay.frame = window.bounds
        window.addSubview(overlay)
    }

    /// 成功時はオーバーレイを除去してから `onFinished(true)`。10回失敗時は失敗表示のまま `onFinished(false)`。
    func runThenInvokeOnMain(onFinished: @escaping (_ success: Bool) -> Void) {
        Task { @MainActor in
            var succeeded = false
            for attempt in 1...Self.maxAttempts {
                do {
                    try AudioSessionConfigurator.activationAttempt()
                    succeeded = true
                    break
                } catch {
                    logger.error("activationAttempt failed attempt \(attempt, privacy: .public): \(String(describing: error), privacy: .public)")
                    if attempt < Self.maxAttempts {
                        try? await Task.sleep(nanoseconds: Self.retryDelayNanoseconds)
                    }
                }
            }

            if succeeded {
                overlay.removeFromSuperview()
                onFinished(true)
            } else {
                statusLabel.text = "失敗しました"
                overlay.accessibilityLabel = "失敗しました"
                UIAccessibility.post(notification: .layoutChanged, argument: statusLabel)
                onFinished(false)
            }
        }
    }
}
