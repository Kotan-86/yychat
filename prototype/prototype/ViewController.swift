//
//  ViewController.swift
//  prototype
//
//  Created by 齋藤光貴 on 2026/04/07.
//

import UIKit

class ViewController: UIViewController {

    private let speechController = SpeechSynthesizerController()

    override func viewDidLoad() {
        super.viewDidLoad()
        try? AudioSessionConfigurator.configureAudioSession()
    }

    @IBAction func speakButtonTapped(_ sender: UIButton) {
        do {
            try speechController.speak(text: "Hello World")
        } catch {
            print("読み上げを開始できませんでした: \(error)")
        }
    }
}
