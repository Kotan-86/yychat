//
//  ViewController.swift
//  prototype
//
//  Created by 齋藤光貴 on 2026/04/07.
//

import UIKit

class ViewController: UIViewController, UITextViewDelegate {

    private let speechController = SpeechSynthesizerController()

    @IBOutlet private weak var inputTextView: UITextView!

    private var autoSendWorkItem: DispatchWorkItem?
    private let autoSendDelay: TimeInterval = 0.5

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(inputTextView != nil, "inputTextView outlet is not connected")
        try? AudioSessionConfigurator.configureAudioSession()

        inputTextView.delegate = self
        inputTextView.returnKeyType = .send
        inputTextView.enablesReturnKeyAutomatically = true
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard text == "\n" else { return true }

        let inputText = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard inputText.isEmpty == false else { return false }
    
        do {
            try speechController.speak(text: inputText)
            textView.text = ""
        } catch {
            print("読み上げを開始できませんでした: \(error)")
        }

        return false
    }

    func textViewDidChange(_ textView: UITextView) {
        autoSendWorkItem?.cancel()

        if textView.markedTextRange != nil { return }

        let work = DispatchWorkItem { [weak self, weak textView] in
            guard let self, let textView else { return }
            self.sendIfPossible(from: textView)
        }

        autoSendWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + autoSendDelay, execute: work)
    }

    private func sendIfPossible(from textView: UITextView) {
        let inputText = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard inputText.isEmpty == false else { return }
        do {
            try speechController.speak(text: inputText)
            textView.text = ""
        } catch {
            print("読み上げを開始できませんでした: \(error)")
        }
    }
}
