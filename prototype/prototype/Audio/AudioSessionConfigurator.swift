//
//  AudioSessionConfigurator.swift
//  prototype
//
//  Created by 齋藤光貴 on 2026/04/07.
//

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
}
