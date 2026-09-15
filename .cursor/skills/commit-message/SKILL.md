---
name: commit-message
description: Creates git commits with Why/What formatted messages when explicitly requested. Use when the user asks to commit changes, create a git commit, or mentions @commit-message. Does not commit without explicit user request.
disable-model-invocation: true
---

# Git コミット

ユーザーがコミット作成を明示的に依頼したときのみ適用する。依頼が無い限りコミットしない。

## コミット前

1. git status / git diff で変更内容を確認する
2. 秘密情報（.env, 認証情報など）が含まれていないか確認する

## メッセージ形式

<タイプ>: <簡潔な説明（What）>

<任意: 変更理由（Why）を1〜2文>
**タイプ:** `feat` / `fix` / `docs` / `refactor` / `test` / `chore`

**例:**
docs: ユーザー認証の受入基準を追加した。

- ログイン失敗時の挙動が未定義だったため、仕様を明文化した。

Issue 参照: 本文末尾に `Fixes #123` または `Refs #123`

## 安全

- git config を変更しない
- フックをスキップしない（ユーザー明示時を除く）
- force push 等の破壊的操作はユーザー明示がない限り行わない

## コミット実行

1. `git status` / `git diff` / `git log` で変更内容と直近のメッセージ形式を確認する
2. 上記形式でメッセージを起草する（Why を本文に、Issue は `Fixes #N` または `Refs #N`）
3. 関連ファイルをステージし、HEREDOC でコミットする
4. `git status` で成功を確認する
5. フック失敗時は amend せず修正して新規コミットする

## 追加リソース

- タイプ別の例は [examples.md](examples.md) を参照
