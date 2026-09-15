/// Feature 向け内部ドメインイベント。ホスト公開契約には含めない。
// 仕様: docs/spec/speech-support-sdk.md#7-含めないもの
enum TextAreaInputEvent {
    case userTypedComposingCharacter(text: String)
    case userDeletedComposingCharacter(text: String)
    case userChangedConfirmedText(text: String)
    case userPressedReturnKey(text: String)
}
