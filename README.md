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

読み上げ方式の製品方針は **確定読み＋効果音（方式A）** です（[ADR: 入力読み上げ方式](docs/spec/ADR_feature-reads-method.md)）。方式Bは製品 SDK 対象外です。発言支援ロジックは [`SpeechSupport`](SpeechSupport/) パッケージとして配布し、プロトタイプがその第一ホストです（[発言支援 SDK 仕様](docs/spec/speech-support-sdk.md)）。

## 想定する価値

- **ろう・難聴者** — チャット入力感覚で、言いたいことが途中から届く
- **聴者** — 音声会話に近い感覚で聞け、入力様子を見なくても「どれくらい続きそうか」が分かる
- **双方** — 発言手段が違っても、待ち合わせのストレスを減らし、スムーズにコミュニケーションできる

## リポジトリ構成

| パス              | 内容                                          |
| ----------------- | --------------------------------------------- |
| `SpeechSupport/`  | 発言支援 SDK（Swift Package・方式A・UI なし） |
| `prototype/`      | iOS プロトタイプ（Xcode・SDK の第一ホスト）   |
| `docs/spec/`      | 機能仕様・ADR（Architecture Decision Record） |
| `reflection/`     | 開発振り返り（仕様ではない）                  |
| `.cursor/skills/` | 仕様駆動開発の AI 向けスキル                  |

## ドキュメント

| 種類       | パス                                                                                           | 内容                                                                                                               |
| ---------- | ---------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| 機能仕様   | [docs/spec/timeline-screen.md](docs/spec/timeline-screen.md)                                   | タイムライン画面の What・受入基準（ライブラリ境界ではない）                                                        |
| 機能仕様   | [docs/spec/speech-support-sdk.md](docs/spec/speech-support-sdk.md)                             | 発言支援 SDK（方式A・UI なし）のホスト向け配布契約・受入基準                                                       |
| 確認リスト | [docs/spec/yy-transcription-spike-checklist.md](docs/spec/yy-transcription-spike-checklist.md) | YY文字起こし向けスパイク確認項目（本番組み込みは別判断）                                                           |
| ADR        | [docs/spec/ADR\_\*.md](docs/spec/)                                                             | 技術・UX 方針の決定記録（[発言支援ライブラリ化](docs/spec/ADR_speech-support-library.md) は **承認**、他は提案中） |

主な ADR:

- [ADR_architecture-refactoring.md](docs/spec/ADR_architecture-refactoring.md) — MVVM + Feature プラグイン構成
- [ADR_feature-reads-method.md](docs/spec/ADR_feature-reads-method.md) — 読み上げ方式の比較と推奨方針
- [ADR_swift-framework.md](docs/spec/ADR_swift-framework.md) — UIKit / AVFoundation など技術選定
- [ADR_speech-support-library.md](docs/spec/ADR_speech-support-library.md) — 発言支援ロジックの外部ライブラリ化方針

## 開発の進め方（仕様駆動）

1. 機能変更前に `docs/spec/` を更新する（**Why** と **What**。受入基準は測定可能に）
2. 実装後、コードに仕様へのリンクを付与する（例: `// 仕様: docs/spec/input-screen.md#確定読み上げ`）
3. 技術選定の変更は ADR を追加・更新する（実装の詳細 **How** は ADR にも仕様にも書きすぎない）

## 開発環境セットアップ

音声認識基盤（YYAPIs gRPC）をビルドするために、次の 2 種類の「ライブラリ」を区別してください。

| 種類                          | 内容                                                      | いつ必要か                                        |
| ----------------------------- | --------------------------------------------------------- | ------------------------------------------------- |
| **A. アプリ依存（SPM）**      | grpc-swift 3 パッケージ（`GRPCCore` 等）                  | **ビルドのたびに必須**                            |
| **B. 開発ツール（Homebrew）** | `swift-protobuf`, `grpc-swift`（`protoc` プラグイン付き） | **proto から `.swift` を再生成するときのみ**      |
| **C. ランタイム設定**         | Scheme 環境変数 `API_KEY`                                 | **音声認識 API を実際に叩くとき**（Phase 3 以降） |

### A. 必須: Xcode + Swift Package Manager

1. **Xcode 16 以降**（grpc-swift 2.x / iOS 18 SDK 向け生成コードと相性）
2. [prototype/prototype.xcodeproj](prototype/prototype.xcodeproj) を開く
3. **File → Add Package Dependencies…** で次の 3 リポジトリを追加（いずれも **Up to Next Major**）

| リポジトリ URL                                         | 最小バージョン | リンクする Product（`prototype` ターゲット） |
| ------------------------------------------------------ | -------------- | -------------------------------------------- |
| `https://github.com/grpc/grpc-swift.git`               | 2.1.0          | **GRPCCore**                                 |
| `https://github.com/grpc/grpc-swift-nio-transport.git` | 1.0.1          | **GRPCNIOTransportHTTP2**                    |
| `https://github.com/grpc/grpc-swift-protobuf.git`      | 1.1.0          | **GRPCProtobuf**                             |

4. 初回は **File → Packages → Resolve Package Versions**（またはビルド時に自動解決）
5. **Product → Clean Build Folder** → Build

`swift-protobuf` 等の transitive 依存は SPM が解決するため、アプリターゲットへ直リンクは不要です。

### B. 任意: Homebrew（proto 再生成のみ）

`yysystem.proto` を編集して Swift を出し直すときだけ:

```bash
brew install swift-protobuf grpc-swift
prototype/scripts/proto-gen.sh
```

Phase 1 では生成済みの `prototype/prototype/Speech/Protos/` を同梱しているため、**通常のビルドでは brew は不要**です。

### C. 音声認識 API 利用時: API キー

- [YYAPIs 開発者コンソール](https://api-web.yysystem2021.com) で API キーと `yysystem.proto` を取得
- **Edit Scheme → Run → Environment Variables:** `API_KEY` = キー文字列
- Phase 1–2 のコード移植だけでは起動テストに不要。`RecognizerClient` を動かす Phase 3 以降で設定

## プロトタイプの起動

1. [prototype/prototype.xcodeproj](prototype/prototype.xcodeproj) を Xcode で開く
2. 上記 **開発環境セットアップ** の SPM 依存を追加済みであること
3. ターゲット `prototype` を選び、実機またはシミュレータで Run
4. **要件:** iOS **18.0** 以降（`IPHONEOS_DEPLOYMENT_TARGET`。YYAPIs 生成コードの `@available(iOS 18.0, …)` および grpc-swift 2.x 採用に合わせた）

音声読み上げ・効果音のため、初回起動時にマイク／オーディオまわりの権限・セッション設定が走る場合があります。

## 現状とスコープ外

- 本リポジトリは **プロトタイプ段階** です。YY文字起こしへの本番組み込み可否はスパイク確認後の別判断（[スパイク確認項目](docs/spec/yy-transcription-spike-checklist.md)）。YYProbe は初回スコープ外（[ADR_swift-framework.md](docs/spec/ADR_swift-framework.md) 参照）
- **Android**、**クラウド TTS**（Google Cloud TTS 等）はスコープ外（将来の検討事項は ADR に記載）
- **Return キー読み上げ**は仕様に含めません（`ReadAloudOnReturnFeature` は仕様外のため、本番化前に整理予定）
