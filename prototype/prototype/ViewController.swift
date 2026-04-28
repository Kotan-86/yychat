import Combine
import OSLog
import UIKit

class ViewController: UIViewController, UITextViewDelegate {

    @IBOutlet private weak var inputTextView: UITextView!
    var viewModel: InputScreenViewModel!
    private var cancellables: Set<AnyCancellable> = []
    private let logger = Logger(subsystem: "yysystem.prototype", category: "ViewController")

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(inputTextView != nil, "inputTextView outlet is not connected")
        precondition(viewModel != nil, "InputScreenViewModel must be injected by InputScreenComposer")
        logger.info("viewDidLoad: viewModel injected")

        inputTextView.delegate = self
        inputTextView.returnKeyType = .send
        inputTextView.enablesReturnKeyAutomatically = true
        bindViewModel()
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
}
