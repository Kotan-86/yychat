import AVFoundation

final class AudioEffectPlayer {
    private var hitPlayers: [AVAudioPlayer] = []
    private var deletePlayer: AVAudioPlayer?
    private var hitPlayerIndex = 0

    init() {
        hitPlayers = (0..<2).compactMap { _ in
            loadAudioPlayer(resourceName: "input_hit", fileExtension: "mp3")
        }
        deletePlayer = loadAudioPlayer(resourceName: "delete_down", fileExtension: "mp3")
    }

    func playHit() {
        guard hitPlayers.isEmpty == false else { return }
        let player = hitPlayers[hitPlayerIndex]
        hitPlayerIndex = (hitPlayerIndex + 1) % hitPlayers.count
        player.currentTime = 0
        player.play()
    }

    func playDelete() {
        guard let deletePlayer else { return }
        deletePlayer.currentTime = 0
        deletePlayer.play()
    }

    private func loadAudioPlayer(resourceName: String, fileExtension: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(
            forResource: resourceName,
            withExtension: fileExtension
        ) else {
            print("効果音ファイルが見つかりません: \(resourceName).\(fileExtension)")
            return nil
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            return player
        } catch {
            print("効果音プレイヤーを初期化できませんでした: \(resourceName).\(fileExtension), error: \(error)")
            return nil
        }
    }
}
