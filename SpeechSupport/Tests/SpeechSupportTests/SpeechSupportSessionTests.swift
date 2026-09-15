import Combine
import Foundation
import XCTest
@testable import SpeechSupport

// 仕様: docs/spec/speech-support-sdk.md#受入基準
final class SpeechSupportSessionTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    func testDebouncedConfirmedTextEmitsSpokenAndClearRequest() {
        // 仕様: docs/spec/speech-support-sdk.md#受入基準
        let speech = MockTextToSpeechEngine()
        let session = makeSession(speech: speech, debounceInterval: 0.05)

        var spoken: [String] = []
        var clearCount = 0
        session.spokenText.sink { spoken.append($0) }.store(in: &cancellables)
        session.clearTextRequest.sink { clearCount += 1 }.store(in: &cancellables)

        session.notifyTextDidChange(currentText: "こんにちは", isComposing: false)

        let spokenExpectation = expectation(description: "spoken")
        session.spokenText.sink { _ in spokenExpectation.fulfill() }.store(in: &cancellables)
        wait(for: [spokenExpectation], timeout: 1.0)

        XCTAssertEqual(spoken, ["こんにちは"])
        XCTAssertEqual(clearCount, 1)
        XCTAssertEqual(speech.spokenTexts, ["こんにちは"])
    }

    func testWhitespaceOnlyDoesNotEmitSpokenOrClear() {
        // 仕様: docs/spec/speech-support-sdk.md#受入基準
        let speech = MockTextToSpeechEngine()
        let session = makeSession(speech: speech, debounceInterval: 0.05)

        var spoken: [String] = []
        var clearCount = 0
        session.spokenText.sink { spoken.append($0) }.store(in: &cancellables)
        session.clearTextRequest.sink { clearCount += 1 }.store(in: &cancellables)

        session.notifyTextDidChange(currentText: "   \n", isComposing: false)

        let waitExpectation = expectation(description: "debounce window")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            waitExpectation.fulfill()
        }
        wait(for: [waitExpectation], timeout: 1.0)

        XCTAssertTrue(spoken.isEmpty)
        XCTAssertEqual(clearCount, 0)
        XCTAssertTrue(speech.spokenTexts.isEmpty)
    }

    func testSpeakFailureDoesNotEmitSpokenOrClear() {
        // 仕様: docs/spec/speech-support-sdk.md#受入基準
        let speech = MockTextToSpeechEngine()
        speech.shouldFail = true
        let session = makeSession(speech: speech, debounceInterval: 0.05)

        var spoken: [String] = []
        var clearCount = 0
        session.spokenText.sink { spoken.append($0) }.store(in: &cancellables)
        session.clearTextRequest.sink { clearCount += 1 }.store(in: &cancellables)

        session.notifyTextDidChange(currentText: "失敗", isComposing: false)

        let waitExpectation = expectation(description: "debounce window")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            waitExpectation.fulfill()
        }
        wait(for: [waitExpectation], timeout: 1.0)

        XCTAssertTrue(spoken.isEmpty)
        XCTAssertEqual(clearCount, 0)
    }

    func testReturnOrSendAloneDoesNotReRead() {
        // 仕様: docs/spec/speech-support-sdk.md#受入基準
        let speech = MockTextToSpeechEngine()
        let session = makeSession(speech: speech, debounceInterval: 0.05)

        var spoken: [String] = []
        session.spokenText.sink { spoken.append($0) }.store(in: &cancellables)

        session.notifyReturnOrSendPressed(text: "再読み上げしない")

        let waitExpectation = expectation(description: "no re-read window")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            waitExpectation.fulfill()
        }
        wait(for: [waitExpectation], timeout: 1.0)

        XCTAssertTrue(spoken.isEmpty)
        XCTAssertTrue(speech.spokenTexts.isEmpty)
    }

    func testIsSpeakingReflectsSpeechLifecycle() {
        // 仕様: docs/spec/speech-support-sdk.md#受入基準
        let speech = MockTextToSpeechEngine()
        speech.finishSpeakingSynchronously = false
        let session = makeSession(speech: speech, debounceInterval: 0.05)

        var speakingValues: [Bool] = []
        session.isSpeaking
            .removeDuplicates()
            .sink { speakingValues.append($0) }
            .store(in: &cancellables)

        session.notifyTextDidChange(currentText: "状態", isComposing: false)

        let speakingExpectation = expectation(description: "isSpeaking true")
        session.isSpeaking
            .filter { $0 }
            .sink { _ in speakingExpectation.fulfill() }
            .store(in: &cancellables)
        wait(for: [speakingExpectation], timeout: 1.0)
        XCTAssertTrue(session.isSpeakingValue)

        speech.finishSpeaking()
        XCTAssertFalse(session.isSpeakingValue)
        XCTAssertEqual(speakingValues.last, false)
    }

    private func makeSession(
        speech: MockTextToSpeechEngine,
        debounceInterval: TimeInterval
    ) -> SpeechSupportSession {
        SpeechSupportSession(
            speech: speech,
            audioEffectPlayer: AudioEffectPlayer(),
            debounceInterval: debounceInterval
        )
    }
}

private enum MockSpeechError: Error {
    case forcedFailure
}

private final class MockTextToSpeechEngine: TextToSpeechEngine {
    var onSpeakingStateChanged: ((Bool) -> Void)?
    var shouldFail = false
    var finishSpeakingSynchronously = true
    private(set) var spokenTexts: [String] = []

    func speak(text: String) throws {
        if shouldFail {
            throw MockSpeechError.forcedFailure
        }
        spokenTexts.append(text)
        onSpeakingStateChanged?(true)
        if finishSpeakingSynchronously {
            onSpeakingStateChanged?(false)
        }
    }

    func stopSpeaking() {
        onSpeakingStateChanged?(false)
    }

    func finishSpeaking() {
        onSpeakingStateChanged?(false)
    }
}
