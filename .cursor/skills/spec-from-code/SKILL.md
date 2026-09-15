---
name: spec-from-code
description: Reverse-engineers or updates specifications from existing code, extracting What, Why, and acceptance criteria without copying implementation details. Use when documenting undocumented code, syncing specs with implementation, when the user mentions @spec-from-code or コードから仕様, or asks to derive specs from source.
disable-model-invocation: true
---

# コードから仕様を書く・修正する

仕様: docs/tools/prompts.md#コードから仕様を逆生成するプロンプト

## 手順

1. 対象コードを読む
2. 既存仕様（docs/spec/\*.md, README.md）を確認し整合性を取る
3. 仕様に含める内容:
   - What: コードが何をするか
   - Why: なぜ必要か（推測部分は明示しユーザーに確認）
   - 受入基準: 満たすべき条件・テスト観点
4. 出力先を提案する（README.md または docs/spec/[機能名].md）

## 注意

- コードの How をそのまま仕様にコピーしない
- 既存仕様と矛盾がある場合は、矛盾点を列挙してから修正案を提示する

## このリポジトリでの補足

- 仕様ファイルの実体は `app/docs/spec/[機能名].md`（手順 2・4 の `docs/spec/` は本リポジトリでは `app/docs/spec/` を読む・書く）
- 仕様の記述形式は `@spec-writing` スキルに従う
- 仕様の作成・更新のみ。実装・テスト・lint は行わない
- コード内の `// 仕様: app/docs/spec/...` コメントは、対象仕様の手がかりとして読む

## 追加リソース

- What / Why / 受入基準の書き分け例は [examples.md](examples.md) を参照
