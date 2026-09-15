// 仕様: docs/spec/speech-support-sdk.md#7-含めないもの
// 製品経路は方式A（readsConfirmedText）のみ。readsCharacterByCharacter は方式B参照用で製品配線しない。
enum InputSpeechReadMode {
    case readsConfirmedText
    case readsCharacterByCharacter
}
