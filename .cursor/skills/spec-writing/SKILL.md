---
name: spec-writing
description: Creates and updates feature specifications with Why, What, and measurable acceptance criteria in app/docs/spec/. Use when writing or updating specs, creating app/docs/spec/*.md, when the user mentions @spec-writing or 仕様のみ, or asks for specification without implementation.
disable-model-invocation: true
---

# 仕様を書く・更新する

仕様: docs/tools/prompts.md#基本的なcursorrules（小規模チーム向け）

## 記述ルール

- Why（なぜ）と What（何を）を必ず書く
- issue 番号を必ず書く
- 受入基準は測定可能・テスト可能な形で書く
- 変更理由を記録する
- How（実装詳細）は書かない
- 曖昧な表現（「適切に」「必要に応じて」）を避ける
- 見出しは明確で具体的にする
- 仕様を書く・更新するのみで、実装はしない

## 新規作成時

1. issue 番号 → 目的（Why）→ 実現内容（What）→ 受入基準 → 制約・関連機能の順に確認する
2. 不明点は推測せずユーザーに質問する
3. GitHub Flavored Markdown で出力する

## 出力先

- 機能単位: `app/docs/spec/[機能名].md`

## ワークフロー

### 新規作成

1. issue 番号・Why・What・受入基準・制約をユーザーと確認する（不足があれば質問）
2. 下記テンプレートに沿って `app/docs/spec/[機能名].md` を作成する
3. 実装・テスト・lint は行わない

### 既存仕様の更新

1. 対象ファイルを読み、変更箇所の Why / What / 受入基準を更新する
2. `## 変更理由` に今回の変更の背景を追記する
3. 実装・テスト・lint は行わない

## テンプレート

```markdown
# [機能名] — [一行要約]

## Issue

#[番号]

## 目的（Why）

[なぜこの変更が必要か]

## 実現内容（What）

[何を実現するか。ユーザー視点・画面・振る舞いで書く]

## 受入基準

1. **[条件]**: [測定可能・テスト可能な期待結果]
2. ...

## 制約・関連機能

- [関連 UI / API / 既存仕様への参照]

## 変更理由

- issue #[番号]: [今回の変更の背景]
```

## 追加リソース

- 完成例は [examples.md](examples.md) を参照
