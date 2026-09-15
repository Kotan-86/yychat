import AVFoundation

// 仕様: docs/spec/speech-support-sdk.md#4-方式aの振る舞いsdk-が保証する
// 未差し替え時も同梱の既定アセットで変換中フィードバックを鳴らす。
final class AudioEffectPlayer {
    private var hitPlayers: [AVAudioPlayer] = []
    private var deletePlayer: AVAudioPlayer?
    private var hitPlayerIndex = 0
    /// 受入検証用。再生要求回数（実音の成否とは独立）。
    private(set) var hitPlayCount = 0
    private(set) var deletePlayCount = 0

    init(overrides: SoundEffectOverrides = SoundEffectOverrides()) {
        if let hitURL = overrides.hitURL {
            hitPlayers = (0..<2).compactMap { _ in loadAudioPlayer(url: hitURL) }
        } else {
            hitPlayers = (0..<2).compactMap { _ in
                loadBundledAudioPlayer(resourceName: "input_hit", fileExtension: "mp3")
            }
        }

        if let deleteURL = overrides.deleteURL {
            deletePlayer = loadAudioPlayer(url: deleteURL)
        } else {
            deletePlayer = loadBundledAudioPlayer(resourceName: "delete_down", fileExtension: "mp3")
        }
    }

    func playHit() {
        hitPlayCount += 1
        guard hitPlayers.isEmpty == false else { return }
        let player = hitPlayers[hitPlayerIndex]
        hitPlayerIndex = (hitPlayerIndex + 1) % hitPlayers.count
        player.currentTime = 0
        player.play()
    }

    func playDelete() {
        deletePlayCount += 1
        guard let deletePlayer else { return }
        deletePlayer.currentTime = 0
        deletePlayer.play()
    }

    private func loadBundledAudioPlayer(resourceName: String, fileExtension: String) -> AVAudioPlayer? {
        guard let url = Bundle.module.url(
            forResource: resourceName,
            withExtension: fileExtension
        ) else {
            print("効果音ファイルが見つかりません: \(resourceName).\(fileExtension)")
            return nil
        }
        return loadAudioPlayer(url: url)
    }

    private func loadAudioPlayer(url: URL) -> AVAudioPlayer? {
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            return player
        } catch {
            print("効果音プレイヤーを初期化できませんでした: \(url.lastPathComponent), error: \(error)")
            return nil
        }
    }
}
