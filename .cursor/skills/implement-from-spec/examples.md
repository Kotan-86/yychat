# 仕様リンクコメントの例

## TypeScript / JavaScript

ファイル先頭または対象関数の直上に付ける。

```typescript
// 仕様: app/docs/spec/bottom-nav-unauthenticated.md#2-未ログイン時の下部ナビ4個目ボタン
```

見出しへのリンクが不要な場合:

```typescript
// 仕様: app/docs/spec/find-yysan-period.md
```

## テストファイル

受入基準に対応するテストには、該当セクションへのリンクを付ける。

```typescript
// 仕様: app/docs/spec/find-yysan-period.md#受入基準
```

```typescript
// 仕様: app/docs/spec/bottom-nav-unauthenticated.md
```

## 仕様・コード・テストの整合

| 変更内容               | 更新対象                                          |
| ---------------------- | ------------------------------------------------- |
| 受入基準を満たす実装   | コード + 仕様リンクコメント                       |
| 受入基準の検証         | テスト + 仕様リンクコメント                       |
| 実装で仕様と乖離が判明 | 仕様（Why/What/受入基準）を先に更新してからコード |

## 仕様に無い振る舞いを追加しようとしたとき

1. ユーザーに仕様更新を提案する（`@spec-writing` スキルに従う）
2. 仕様が合意・更新されるまで実装しない
