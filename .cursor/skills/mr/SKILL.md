---
name: mr
description: 現在の変更に対して Merge Request を作成する
disable-model-invocation: true
---
現在の変更に対して Merge Request を作成してください。

## 手順

1. `git diff` で変更内容を確認
2. （developブランチにいる場合のみ）変更内容に沿ったブランチを作成し、そのブランチにチェックアウトする
3. Conventional Commits に従ったコミットメッセージを作成し、変更をコミット
4. `git push -o merge_request.create -o merge_request.target=develop`
5. 作成された MR URL を出力

## 制約

- コミットメッセージは commitlint の @commitlint/config-conventional に適合させること
