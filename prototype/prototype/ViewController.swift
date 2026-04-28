import Combine
import OSLog
import UIKit

class ViewController: UIViewController, UITextViewDelegate {

    @IBOutlet private weak var inputTextView: UITextView!
    @IBOutlet private weak var readsConfirmedTextModeButton: UIButton!
    @IBOutlet private weak var readsCharacterByCharacterModeButton: UIButton!
    var viewModel: InputScreenViewModel!
    private var cancellables: Set<AnyCancellable> = []
    private let logger = Logger(subsystem: "yysystem.prototype", category: "ViewController")

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(inputTextView != nil, "inputTextView outlet is not connected")
        precondition(self.viewModel != nil, "InputScreenViewModel must be injected by InputScreenComposer")
        logger.info("viewDidLoad: viewModel injected")

        inputTextView.delegate = self
        inputTextView.returnKeyType = .send
        inputTextView.enablesReturnKeyAutomatically = true
        logger.info("viewDidLoad: mode before initial send=\(String(describing: self.viewModel.speechReadMode.value), privacy: .public)")
        self.viewModel.selectSpeechReadMode(.readsConfirmedText)
        logger.info("viewDidLoad: mode after initial send=\(String(describing: self.viewModel.speechReadMode.value), privacy: .public)")
        bindViewModel()
    }

    @IBAction private func didTapReadsConfirmedTextModeButton(_ sender: UIButton) {
        logger.info("tap: readsConfirmedText button")
        self.viewModel.selectSpeechReadMode(.readsConfirmedText)
        logger.info("tap result: current mode=\(String(describing: self.viewModel.speechReadMode.value), privacy: .public)")
    }

    @IBAction private func didTapReadsCharacterByCharacterModeButton(_ sender: UIButton) {
        logger.info("tap: readsCharacterByCharacter button")
        self.viewModel.selectSpeechReadMode(.readsCharacterByCharacter)
        logger.info("tap result: current mode=\(String(describing: self.viewModel.speechReadMode.value), privacy: .public)")
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard text == "\n" else { return true }
        logger.debug("return key pressed. textLength=\(textView.text?.count ?? 0)")
        viewModel.onTextAreaReturnKeyDidPress(text: textView.text ?? "")
        return false
    }

    func textViewDidChange(_ textView: UITextView) {
        let currentText = textView.text ?? ""
        let isComposing = textView.markedTextRange != nil
        logger.debug("textViewDidChange: textLength=\(currentText.count), isComposing=\(isComposing)")
        viewModel.onTextAreaTextDidChange(currentText: currentText, isComposing: isComposing)
    }

    private func bindViewModel() {
        viewModel.speechReadMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] mode in
                guard let self else { return }
                self.logger.info("speechReadMode observed in ViewController: \(String(describing: mode), privacy: .public)")
                self.applySpeechReadModeSelection(mode)
            }
            .store(in: &cancellables)

        viewModel.displayState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                if self.inputTextView.text != state.text {
                    self.logger.debug("displayState applied: textLength=\(state.text.count)")
                    self.inputTextView.text = state.text
                }
            }
            .store(in: &cancellables)
    }

    private func applySpeechReadModeSelection(_ mode: InputSpeechReadMode) {
        let isReadsConfirmedText = (mode == .readsConfirmedText)
        readsConfirmedTextModeButton.isSelected = isReadsConfirmedText
        readsCharacterByCharacterModeButton.isSelected = (isReadsConfirmedText == false)

        readsConfirmedTextModeButton.alpha = isReadsConfirmedText ? 1.0 : 0.6
        readsCharacterByCharacterModeButton.alpha = isReadsConfirmedText ? 0.6 : 1.0
    }
}
