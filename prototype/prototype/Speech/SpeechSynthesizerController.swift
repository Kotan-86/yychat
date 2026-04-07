//
//  SpeechSynthesizerController.swift
//  prototype
//
//  Created by 齋藤光貴 on 2026/04/07.
//

import AVFoundation


// 音声合成と再生を行うクラス
final class SpeechSynthesizerController {
    private let synthesizer = AVSpeechSynthesizer()

    init() {
        synthesizer.usesApplicationAudioSession = true
    }

    func speak(text: String) throws {
        try AudioSessionConfigurator.configureAudioSession()
        try AudioSessionConfigurator.activateSession()

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        synthesizer.speak(utterance)
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}

