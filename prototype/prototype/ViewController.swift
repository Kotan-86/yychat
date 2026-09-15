import Combine
import OSLog
import SpeechSupport
import SwiftProtobuf
import UIKit

// 仕様: docs/spec/timeline-screen.md
// 仕様: docs/spec/speech-support-sdk.md#5-セッションと配線
class ViewController: UIViewController, UITextViewDelegate, UITableViewDataSource, UITableViewDelegate, AudioControllerDelegate, UIGestureRecognizerDelegate {

    @IBOutlet private weak var timelineTableView: UITableView!
    @IBOutlet private weak var draftLabel: UILabel!
    @IBOutlet private weak var scrollToBottomButton: UIButton!
    @IBOutlet private weak var speechRecognitionToggleButton: UIButton!
    @IBOutlet private weak var inputTextView: UITextView!

    var viewModel: InputScreenViewModel!
    /// 発言支援は公開 API（`SpeechSupportSession`）のみ利用する。
    var speechSupport: SpeechSupportSession!
    private var cancellables: Set<AnyCancellable> = []
    private let logger = Logger(subsystem: "yysystem.prototype", category: "ViewController")
    private let recognizerClient = RecognizerClient()
    private let audioController = AudioController.shared

    private var timelineMessages: [TimelineMessage] = []
    private var isAutoScrollEnabled = true
    private var isRecognitionRunning = false
    private var recognitionTask: Task<Void, Never>?
    private var currentReceivedMessageID: UUID?
    private lazy var keyboardDismissTapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapBackgroundToDismissKeyboard))
        gesture.cancelsTouchesInView = false
        gesture.delegate = self
        return gesture
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(timelineTableView != nil, "timelineTableView outlet is not connected")
        assert(draftLabel != nil, "draftLabel outlet is not connected")
        assert(scrollToBottomButton != nil, "scrollToBottomButton outlet is not connected")
        assert(speechRecognitionToggleButton != nil, "speechRecognitionToggleButton outlet is not connected")
        assert(inputTextView != nil, "inputTextView outlet is not connected")
        precondition(self.viewModel != nil, "InputScreenViewModel must be injected by InputScreenComposer")
        precondition(self.speechSupport != nil, "SpeechSupportSession must be injected by InputScreenComposer")
        logger.info("viewDidLoad: viewModel and speechSupport injected")

        setupTimelineTableView()
        setupDraftLabel()
        setupScrollToBottomButton()
        setupSpeechRecognitionToggleButton()
        setupKeyboardDismiss()

        inputTextView.delegate = self
        inputTextView.returnKeyType = .send
        inputTextView.enablesReturnKeyAutomatically = true
        bindViewModel()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isRecognitionRunning {
            stopSpeechRecognition()
        }
    }

    @IBAction private func didTapScrollToBottomButton(_ sender: UIButton) {
        isAutoScrollEnabled = true
        scrollToBottomButton.isHidden = true
        scrollToLatest(animated: true)
    }

    @IBAction private func didTapSpeechRecognitionToggleButton(_ sender: UIButton) {
        if isRecognitionRunning {
            stopSpeechRecognition()
        } else {
            startSpeechRecognition()
        }
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard text == "\n" else { return true }
        logger.debug("return key pressed. textLength=\(textView.text?.count ?? 0)")
        viewModel.onReturnKeyDidPress()
        return false
    }

    func textViewDidChange(_ textView: UITextView) {
        let currentText = textView.text ?? ""
        let isComposing = textView.markedTextRange != nil
        logger.debug("textViewDidChange: textLength=\(currentText.count), isComposing=\(isComposing)")
        // 仕様: docs/spec/speech-support-sdk.md#2-ホストが渡す入力事実
        viewModel.inputText.send(currentText)
        speechSupport.notifyTextDidChange(currentText: currentText, isComposing: isComposing)
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        timelineMessages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = timelineMessages[indexPath.row]
        switch message.direction {
        case .sent:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: SentMessageCell.reuseIdentifier,
                for: indexPath
            ) as! SentMessageCell
            cell.configure(text: message.text)
            return cell
        case .received:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ReceivedMessageCell.reuseIdentifier,
                for: indexPath
            ) as! ReceivedMessageCell
            cell.configure(text: message.text, status: message.status)
            return cell
        }
    }

    // MARK: - UIScrollViewDelegate

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard scrollView === timelineTableView else { return }
        isAutoScrollEnabled = false
        scrollToBottomButton.isHidden = false
    }

    // MARK: - Private

    private func setupTimelineTableView() {
        timelineTableView.dataSource = self
        timelineTableView.delegate = self
        timelineTableView.keyboardDismissMode = .onDrag
        timelineTableView.rowHeight = UITableView.automaticDimension
        timelineTableView.estimatedRowHeight = 60
        timelineTableView.separatorStyle = .none
        timelineTableView.backgroundColor = .clear
        timelineTableView.register(
            SentMessageCell.self,
            forCellReuseIdentifier: SentMessageCell.reuseIdentifier
        )
        timelineTableView.register(
            ReceivedMessageCell.self,
            forCellReuseIdentifier: ReceivedMessageCell.reuseIdentifier
        )
    }

    private func setupDraftLabel() {
        draftLabel.isUserInteractionEnabled = false
        draftLabel.numberOfLines = 0
        draftLabel.font = .systemFont(ofSize: 15)
        draftLabel.textColor = .secondaryLabel
        draftLabel.isHidden = true
    }

    private func setupScrollToBottomButton() {
        scrollToBottomButton.isHidden = true
        var config = scrollToBottomButton.configuration ?? UIButton.Configuration.filled()
        config.title = "最新へ"
        config.cornerStyle = .capsule
        scrollToBottomButton.configuration = config
    }

    private func setupSpeechRecognitionToggleButton() {
        applySpeechRecognitionButtonState()
    }

    private func setupKeyboardDismiss() {
        view.addGestureRecognizer(keyboardDismissTapGesture)
    }

    private func bindViewModel() {
        viewModel.inputText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                guard let self else { return }
                if self.inputTextView.text != text {
                    self.logger.debug("inputText applied: textLength=\(text.count)")
                    self.inputTextView.text = text
                }
            }
            .store(in: &cancellables)

        viewModel.timelineMessages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] messages in
                self?.applyTimelineSnapshot(messages)
            }
            .store(in: &cancellables)

        viewModel.draftText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                guard let self else { return }
                self.draftLabel.text = text.isEmpty ? nil : text
                self.draftLabel.isHidden = text.isEmpty
            }
            .store(in: &cancellables)
    }

    private func applyTimelineSnapshot(_ messages: [TimelineMessage]) {
        timelineMessages = messages
        timelineTableView.reloadData()
        if isAutoScrollEnabled {
            scrollToLatest(animated: true)
        }
    }

    private func scrollToLatest(animated: Bool) {
        guard timelineMessages.isEmpty == false else { return }
        let lastIndex = IndexPath(row: timelineMessages.count - 1, section: 0)
        timelineTableView.layoutIfNeeded()
        timelineTableView.scrollToRow(at: lastIndex, at: .top, animated: animated)
    }

    private func applySpeechRecognitionButtonState() {
        var config = speechRecognitionToggleButton.configuration ?? UIButton.Configuration.filled()
        config.title = isRecognitionRunning ? "認識終了" : "認識開始"
        speechRecognitionToggleButton.configuration = config
    }

    private func startSpeechRecognition() {
        guard isRecognitionRunning == false else { return }
        logger.info("speech recognition start requested")

        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.audioController.requestRecordPermission()
                let prepareStatus = self.audioController.prepare(specifiedSampleRate: 16000)
                guard prepareStatus == noErr else {
                    self.logger.error("audio prepare failed: \(prepareStatus)")
                    return
                }
                self.audioController.delegate = self
                let startStatus = self.audioController.start()
                guard startStatus == noErr else {
                    self.logger.error("audio start failed: \(startStatus)")
                    return
                }

                self.isRecognitionRunning = true
                self.applySpeechRecognitionButtonState()

                let stream = try await self.recognizerClient.stream()
                self.recognitionTask = Task { [weak self] in
                    guard let self else { return }
                    do {
                        for try await event in stream {
                            switch event {
                            case .onData(let text, let isFinal):
                                self.handleRecognitionText(text: text, isFinal: isFinal)
                            case .onError(let message):
                                self.logger.error("recognition event error: \(message, privacy: .public)")
                            }
                        }
                    } catch {
                        self.logger.error("recognition stream failed: \(error.localizedDescription, privacy: .public)")
                    }
                }
            } catch {
                self.logger.error("failed to start speech recognition: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func stopSpeechRecognition() {
        guard isRecognitionRunning else { return }
        logger.info("speech recognition stop requested")
        recognitionTask?.cancel()
        recognitionTask = nil
        recognizerClient.stop()
        _ = audioController.stop()
        audioController.delegate = nil
        if let id = currentReceivedMessageID {
            viewModel.finalizeReceived(id: id)
        }
        currentReceivedMessageID = nil
        isRecognitionRunning = false
        applySpeechRecognitionButtonState()
    }

    private func handleRecognitionText(text: String, isFinal: Bool) {
        logger.info("recognition text observed. isFinal=\(isFinal), length=\(text.count)")
        if let id = currentReceivedMessageID {
            viewModel.updateReceivedPartial(id: id, text: text)
            if isFinal {
                if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    viewModel.removeReceived(id: id)
                } else {
                    viewModel.finalizeReceived(id: id)
                }
                currentReceivedMessageID = nil
            }
            return
        }

        let newID = UUID()
        currentReceivedMessageID = newID
        viewModel.addReceivedPartial(id: newID, text: text)
        if isFinal {
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                viewModel.removeReceived(id: newID)
            } else {
                viewModel.finalizeReceived(id: newID)
            }
            currentReceivedMessageID = nil
        }
    }

    // 仕様: docs/spec/timeline-screen.md#音声認識（文字起こし）による受信支援
    func processSampleData(_ data: Data) {
        guard isRecognitionRunning else { return }
        guard viewModel.isSpeaking.value == false else {
            logger.debug("skip recognition write while TTS speaking")
            return
        }
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.recognizerClient.write(.with {
                    $0.audiobytes = data
                })
            } catch {
                self.logger.error("failed to write recognition audio data: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    @objc private func didTapBackgroundToDismissKeyboard() {
        view.endEditing(true)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // ボタンや入力欄のタップは通常操作を優先し、背景タップ時のみキーボードを閉じる。
        if touch.view is UIControl || touch.view is UITextView {
            return false
        }
        return true
    }
}
