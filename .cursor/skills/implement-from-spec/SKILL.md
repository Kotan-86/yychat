---
name: implement-from-spec
description: Implements or modifies code from specifications in app/docs/spec/ or README.md, satisfying acceptance criteria with spec-link comments. Use when implementing features from specs, when the user mentions @implement-from-spec or 仕様から実装, or asks to code against an existing specification.
disable-model-invocation: true
---

# 仕様から実装する

仕様: docs/tools/prompts.md#仕様からコードを生成するプロンプト

## 手順

1. 関連仕様（docs/spec/\*.md または README.md）を読む
2. 仕様が無い・曖昧なら実装前に質問する
3. 受入基準を満たす実装を行う
4. 必要ならテストを追加・更新する
5. コード変更に伴い仕様更新が必要なら同時に更新する
6. 関数・モジュール等に仕様リンクのコメントを付ける

## 部分修正

依頼範囲のみ仕様に合わせて修正する。仕様に無い振る舞いを追加する場合は、先に仕様更新を提案する。

## 複数ファイル更新

仕様・コード・テストの 3 者の整合性を保つ。

## このリポジトリでの補足

- 仕様ファイルの実体は `app/docs/spec/[機能名].md`（手順 1 の `docs/spec/` は本リポジトリでは `app/docs/spec/` を読む）
- コード変更後は `npm run lint` と `npm run typecheck` を実行する（AGENTS.md）
- 仕様リンクの書き方は [examples.md](examples.md) を参照
