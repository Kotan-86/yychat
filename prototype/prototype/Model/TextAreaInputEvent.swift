enum TextAreaInputEvent {
    case userTypedComposingCharacter(text: String)
    case userDeletedComposingCharacter(text: String)
    case userChangedConfirmedText(text: String)
    case userPressedReturnKey(text: String)
}
