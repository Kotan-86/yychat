//
//  ViewController.swift
//  prototype
//
//  Created by 齋藤光貴 on 2026/04/07.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, UITextViewDelegate {

    private let speechController = SpeechSynthesizerController()

    @IBOutlet private weak var inputTextView: UITextView!

    private var autoReadWorkItem: DispatchWorkItem?
    private let autoReadDebounceInterval: TimeInterval = 0.5
    private var lastConfirmedTextForFeedback = ""
    private var suppressNextInputFeedback = false
    private var hitPlayers: [AVAudioPlayer] = []
    private var deletePlayer: AVAudioPlayer?
    private var hitPlayerIndex = 0

    // 画面ロード時にUIを初期化する
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(inputTextView != nil, "inputTextView outlet is not connected")
        try? AudioSessionConfigurator.configureAudioSession()

        inputTextView.delegate = self
        inputTextView.returnKeyType = .send
        inputTextView.enablesReturnKeyAutomatically = true
        lastConfirmedTextForFeedback = inputTextView.text ?? ""
        prepareInputFeedbackSounds()
    }

    // 改行文字入力(エンタキー)でhandleReturnKeyを呼ぶ
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard text == "\n" else { return true }
        return handleReturnKey(in: textView)
    }

    // 入力が変更されたらscheduleAutoReadAfterInputStabilizesを呼ぶ
    func textViewDidChange(_ textView: UITextView) {
        scheduleAutoReadAfterInputStabilizes(for: textView)

        // 元の仕様（確定時のみ効果音）
        // guard textView.markedTextRange == nil else { return }
        // 今回の仕様（未確定時のみ効果音）
        guard textView.markedTextRange != nil else { return }

        let currentText = textView.text ?? ""
        if suppressNextInputFeedback {
            suppressNextInputFeedback = false
            lastConfirmedTextForFeedback = currentText
            return
        }

        guard currentText != lastConfirmedTextForFeedback else { return }
        // 元の仕様（確定テキスト差分で削除判定）
        // if currentText.count < lastConfirmedTextForFeedback.count {
        //     playDeleteFeedbackSound()
        // } else {
        //     playHitFeedbackSound()
        // }

        // 今回の仕様（未確定テキスト差分で削除判定）
        let isDeletingWhileComposing = currentText.count < lastConfirmedTextForFeedback.count
        if isDeletingWhileComposing {
            playDeleteFeedbackSound()
        } else {
            playHitFeedbackSound()
        }
        lastConfirmedTextForFeedback = currentText
    }

    // 改行文字入力(エンタキー)でreadAloudAndClearIfNeededを呼ぶ
    private func handleReturnKey(in textView: UITextView) -> Bool {
        let trimmed = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return false }
        readAloudAndClearIfNeeded(from: textView)
        return false
    }

    // 未確定入力がないときだけ、入力がしばらく止まったあとにreadAloudAndClearIfNeededを呼ぶ
    private func scheduleAutoReadAfterInputStabilizes(for textView: UITextView) {
        autoReadWorkItem?.cancel()
        guard textView.markedTextRange == nil else { return }

        let work = DispatchWorkItem { [weak self, weak textView] in
            guard let self, let textView else { return }
            self.readAloudAndClearIfNeeded(from: textView)
        }
        autoReadWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + autoReadDebounceInterval, execute: work)
    }

    
    // speechController.speakを呼ぶ
    private func readAloudAndClearIfNeeded(from textView: UITextView) {
        let inputText = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard inputText.isEmpty == false else { return }
        do {
            try speechController.speak(text: inputText)
            suppressNextInputFeedback = true
            lastConfirmedTextForFeedback = ""
            textView.text = ""
        } catch {
            print("読み上げを開始できませんでした: \(error)")
        }
    }

    private func prepareInputFeedbackSounds() {
        hitPlayers = (0..<2).compactMap { _ in
            loadAudioPlayer(resourceName: "input_hit", fileExtension: "mp3")
        }
        deletePlayer = loadAudioPlayer(resourceName: "delete_down", fileExtension: "mp3")
    }

    private func loadAudioPlayer(resourceName: String, fileExtension: String) -> AVAudioPlayer? {
        print(Bundle.main.resourcePath ?? "")
        guard let url = Bundle.main.url(
                            forResource: resourceName,
                            withExtension: fileExtension,
                            subdirectory: ""
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

    private func playHitFeedbackSound() {
        guard hitPlayers.isEmpty == false else { return }
        let player = hitPlayers[hitPlayerIndex]
        hitPlayerIndex = (hitPlayerIndex + 1) % hitPlayers.count
        player.currentTime = 0
        player.play()
    }

    private func playDeleteFeedbackSound() {
        guard let deletePlayer else { return }
        deletePlayer.currentTime = 0
        deletePlayer.play()
    }
}
