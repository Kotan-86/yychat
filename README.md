# yychat（仮称）

ろう・難聴者と聴者が、チャット入力感覚と音声会話に近い聞き取りを両立できるコミュニケーション支援アプリのリポジトリです。

## 背景と課題

聴者と雑談する際、いちいち文字を見せるのも手間で、入力者が全部打ち終わるのを待たせたくない——という問題意識から出発したプロダクトです。

既存の YY 系アプリ（YY文字起こし・YYProbe）では、ろう・難聴者はチャット入力で話したいことを伝えられますが、次の課題があります。

- ろう・難聴者は「聴者を待たせる」、聴者は「入力が終わるのを待つ」という時間・手間・心理的障壁が残る
- 文字起こしとチャットの区別がつきにくく、会話の流れが読み取りづらい

本リポジトリでは、**入力の途中から**聴者に伝わる仕組みをプロトタイプで検証します。

## コア機能（プロトタイプで検証中）

1. **確定テキストの自動読み上げ** — 漢字変換確定後、一定時間（0.5秒）入力が止まったら全文を読み上げ、入力欄をクリアする
2. **入力中の効果音** — IME 未確定の文字を追加・削除したとき、それぞれ異なる効果音を鳴らし、入力の継続感を伝える

読み上げ方式は UI 上で切り替え可能です。**推奨は「確定読み＋効果音」**（方式A）です。「1文字ずつ読み」（方式B）は比較・実験用です（[ADR: 入力読み上げ方式](docs/spec/ADR_feature-reads-method.md) 参照）。

## 想定する価値

- **ろう・難聴者** — チャット入力感覚で、言いたいことが途中から届く
- **聴者** — 音声会話に近い感覚で聞け、入力様子を見なくても「どれくらい続きそうか」が分かる
- **双方** — 発言手段が違っても、待ち合わせのストレスを減らし、スムーズにコミュニケーションできる

## リポジトリ構成

| パス | 内容 |
|------|------|
| `prototype/` | iOS プロトタイプ（Xcode プロジェクト） |
| `docs/spec/` | 機能仕様・ADR（Architecture Decision Record） |
| `reflection/` | 開発振り返り（仕様ではない） |
| `.cursor/rules/` | 仕様駆動開発の AI 向けルール |

## ドキュメント

| 種類 | パス | 内容 |
|------|------|------|
| 機能仕様 | [docs/spec/input-screen.md](docs/spec/input-screen.md) | 入力画面の What・受入基準 |
| ADR | [docs/spec/ADR_*.md](docs/spec/) | 技術・UX 方針の決定記録（現状はいずれも **提案中**） |

主な ADR:

- [ADR_architecture-refactoring.md](docs/spec/ADR_architecture-refactoring.md) — MVVM + Feature プラグイン構成
- [ADR_feature-reads-method.md](docs/spec/ADR_feature-reads-method.md) — 読み上げ方式の比較と推奨方針
- [ADR_swift-framework.md](docs/spec/ADR_swift-framework.md) — UIKit / AVFoundation など技術選定

## 開発の進め方（仕様駆動）

1. 機能変更前に `docs/spec/` を更新する（**Why** と **What**。受入基準は測定可能に）
2. 実装後、コードに仕様へのリンクを付与する（例: `// 仕様: docs/spec/input-screen.md#確定読み上げ`）
3. 技術選定の変更は ADR を追加・更新する（実装の詳細 **How** は ADR にも仕様にも書きすぎない）

## プロトタイプの起動

1. [prototype/prototype.xcodeproj](prototype/prototype.xcodeproj) を Xcode で開く
2. ターゲット `prototype` を選び、実機またはシミュレータで Run
3. **要件:** iOS 15.5 以降（`IPHONEOS_DEPLOYMENT_TARGET`）

音声読み上げ・効果音のため、初回起動時にマイク／オーディオまわりの権限・セッション設定が走る場合があります。

## 現状とスコープ外

- 本リポジトリは **プロトタイプ段階** です。YY文字起こし・YYProbe への組み込みは別フェーズ（[ADR_swift-framework.md](docs/spec/ADR_swift-framework.md) 参照）
- **Android**、**クラウド TTS**（Google Cloud TTS 等）はスコープ外（将来の検討事項は ADR に記載）
- **Return キー読み上げ**は仕様に含めません（`ReadAloudOnReturnFeature` は仕様外のため、本番化前に整理予定）
