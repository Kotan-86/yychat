---
name: pull-request
description: Creates GitHub Pull Requests with Why/What formatted descriptions using gh pr create. Use when the user asks to create a PR, generate a PR description, or mentions @pull-request. Does not push without explicit user request.
disable-model-invocation: true
---

# Pull Request（小規模チーム）

ユーザーが PR 作成・PR 説明文生成を依頼したときのみ適用する。

## 前提

- 承認: 1 名で OK
- 品質確認: GitHub の PR レビュー・ブランチ保護に委ねる

## PR 作成前

1. git status / git diff / git log でブランチ状態を確認する
2. 仕様変更を含む場合、関連仕様も更新済みか確認する

## 説明文テンプレート

```markdown
## 変更内容

<!-- 何を変更したか（1〜2文） -->

## 変更の理由

<!-- なぜ変更が必要か（Why） -->

## 関連Issue

Closes #<!-- 番号 -->

## 関連する仕様

<!-- docs/spec/xxx.md または README.md へのリンク -->

## チェックリスト

- [ ] テストが通る
- [ ] 仕様を更新した（必要な場合）
- [ ] 動作確認した
```

## 手順

必要なら git push -u origin HEAD
gh pr create で PR 作成（body は HEREDOC で渡す）
PR URL をユーザーに返す

## 注意

ユーザー明示がない限り push しない
git config を変更しない

---

## GitHub テンプレ（任意・推奨）

各リポジトリの `.github/PULL_REQUEST_TEMPLATE.md` に置くと、Rule 6 と UI 上も揃います。

```markdown
## 変更内容

<!-- 何を変更したか（1〜2文） -->

## 変更の理由

<!-- なぜ変更が必要か（Why） -->

## 関連Issue

Closes #

## 関連する仕様

<!-- docs/spec/xxx.md または README.md へのリンク -->

## チェックリスト

- [ ] テストが通る
- [ ] 仕様を更新した（必要な場合）
- [ ] 動作確認した
```

## このリポジトリでの補足

- 仕様ファイルの実体は `docs/spec/`（スキル原文の `app/docs/spec/` は本リポジトリでは `docs/spec/` をリンクする）
- 発言支援ライブラリ関連の PR では、共通チェックに加え [ADR_speech-support-library.md の Compliance](../../../docs/spec/ADR_speech-support-library.md#compliance以降-pr-のチェックリスト) を説明文へ転記する。Issue は採番まで `Refs #TBD` / `Closes #TBD`
- PR 作成前に `git diff [base-branch]...HEAD` でブランチ全体の変更も確認する
- 記入例と `gh pr create` コマンドは [examples.md](examples.md) を参照
