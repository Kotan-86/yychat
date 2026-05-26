# 【ADR】プロトタイプのアーキテクチャリファクタリング

## Status
提案中(proposed)
> 提案中(proposed): まだ承認されておらず、議論・レビュー中の状態<br>承認(accepted): 承認され、現在有効な決定<br>却下(rejected): 提案されたが採用されなかった決定<br>廃止/非推奨(deprecated/superseded): 以前は有効だったが、後に新たな決定に置き換えられた決定

## Context
* プロトタイプアプリ（`prototype/prototype`）の入力画面は、当初 `ViewController.swift` に **UI・効果音再生・音声合成・入力状態・IME 判定** が集中していた
* その結果、次の問題があった
  * 「表示・画面に関する処理だけにしたい」という意図と乖離し、`AVFoundation` や `SpeechSynthesizerController` が View に同居していた
  * `textViewDidChange` など **1コールバックに複数の副作用**（自動読み上げデバウンス、効果音、テキスト差分記憶など）が直列で書かれ、変更の影響範囲が読みにくかった
  * **新しい入力連動機能を足すたびに `ViewController` を書き換える**必要があり、既存ロジックを壊すリスクがあった
* 目標は次の2点である
  * **MVVM** に従い、View は表示と UI イベントの中継に限定する
  * **拡張に開き修正に閉じる** — 機能追加は主に **コードの追加** で完結し、既存の View / ViewModel / 他 Feature を原則変更しない

## Decision

### アーキテクチャ全体: MVVM と Feature プラグイン

#### 採用する構造
* **View** — `ViewController`（クラス名は Storyboard 参照のため据え置き）。IBOutlet、`UITextViewDelegate`、IME 判定、ViewModel への事実通知、`displayState` の購読による表示反映のみ。音・読み上げの知識を持たない
* **ViewModel** — `InputScreenViewModel`。View から受けた事実をドメイン上の **イベント** に翻訳して発信し、表示用状態を保持。UIKit・デバイス機能に依存しない
* **Model** — `TextAreaInputEvent` / `TextAreaDisplayState` など、**ふるまいを持たないデータ定義**
* **Features** — `InputScreenFeaturePlugin` を実装する **1機能 = 1クラス**（例: `InputFeedbackSoundFeature`、`ReadAloudOnReturnFeature`、`AutoReadDebounceFeature`）。ViewModel の **イベントストリームのみ** を購読し、必要な副作用（効果音・読み上げ・`clearText` など）を完結させる
* **Composition** — `InputScreenComposer`。起動時に ViewModel・各 Feature・外部サービスを生成し `bind` する **唯一の配線箇所**。新機能は **Feature クラスを1つ追加し、ここに1行足す** 方針

#### イベント設計（Model）
* 各 Feature が要求する事象を **最小の4ケース** に分解し、過度な抽象化による「分類ロジックの再実装」を避ける
  * `userTypedComposingCharacter` / `userDeletedComposingCharacter` — IME 未確定中の増減（効果音用）
  * `userChangedConfirmedText` — 確定テキストの変化（debounce 自動読み上げ用）
  * `userPressedReturnKey` — Return 押下（空文字なら発火しない）
* ケース名は **SVO（主語 `user` 固定）** で具体化し、将来のシステムイベントと命名空間が衝突しにくいようにする
* `text` は **その時点の全文** を運び、Feature 側が単一のペイロードで用途を完結できるようにする
* **分類（diff 判定）は ViewModel** に集約し、View は「現在テキスト + 未確定か」を渡すだけにする

#### ViewModel が公開する固定インタフェース
* `events: PassthroughSubject<TextAreaInputEvent, Never>` — 各 Feature の購読点
* `displayState: CurrentValueSubject<TextAreaDisplayState, Never>` — View の購読点
* `clearText()` — 読み上げ後のクリア等、共有副作用はこの公開 API に集約し Feature 同士を疎に保つ

#### 拡張点の契約
* **プロトコル名:** `InputScreenFeaturePlugin`（「Plugin」で契約であることを明示）
* **メソッド:** `bind(to viewModel: InputScreenViewModel)` — 内部で `events` を購読する

### イベント購読基盤

#### 採用する技術
**Combine（`PassthroughSubject` / `CurrentValueSubject` / `debounce` 等）**
* 標準フレームワークであり **型安全** で、非同期・ストリーム処理（自動読み上げの debounce）に適合するため
* iOS 13 以降前提で問題ないため

#### 比較検討（記録）
* **自前 Observer（プロトコル + 配列）** — 外部依存は最小だが、同等の安全さと演算子を自前で積むコストが増えるため不採用
* **クロージャ型イベントバス** — 実装は小さいが、型の強さと保守性で Combine に劣るため不採用

### 効果音プレイヤーの配置

#### 採用する配置
**`Audio/` 配下に `AudioEffectPlayer` を新設**
* 既存の `AudioSessionConfigurator` と同じ **音の基盤レイヤ** に効果音のロード・再生を集約し、**再利用可能な部品**として切り出すため
* View は `AudioEffectPlayer` を直接持たず、**Feature のみ** が利用する

#### 比較検討（記録）
* **`SoundEffect/` 等新ディレクトリ** — `Audio/` を基盤専用に保てるが、本プロトタイプではディレクトリを増やさず **音全般を `Audio/` にまとめる** 方針を優先し不採用
* **`Features/` 配下に音アセット管理を同居** — 機能と資産が強結合し、他画面からの再利用がしづらいため不採用

### 命名規約

#### 画面スコープ（本アプリでは入力画面が唯一）
* ViewModel: `InputScreenViewModel`
* プラグイン契約: `InputScreenFeaturePlugin`
* 配線: `InputScreenComposer`

#### 画面内パーツ（テキストエリア由来）
* `TextAreaInputEvent` / `TextAreaDisplayState`

#### 機能クラス
* **1ファイル = 1クラス**、末尾は `…Feature`

#### View のクラス名
* **`ViewController` はリネームしない** — `Main.storyboard` の Custom Class 参照を壊さないため

### 既存サービス層との関係
* **`SpeechSynthesizerController`** / **`AudioSessionConfigurator`** — 原則 **変更せず**、読み上げ・セッション設定の再利用可能な部品として Feature から利用する
* **依存方向:** `Audio/` と `Speech/` は上位レイヤを知らない。View は ViewModel のみを知り、音・読み上げの存在を知らない

### リファクタリングの進め方（意思決定としての運用ルール）
* **1ステップ = 1機能単位** で進め、各ステップ終了時点で **ビルド可能** な状態を保つ
* 順序は **土台（Model → ViewModel → プラグイン契約 → AudioEffectPlayer）→ 各 Feature の切り出し → ViewController 縮小 → Composer 配線** とする

## Consequences

### メリット
* View が薄くなり、**表示と入力事実の中継**に責務が限定される（`AVFoundation` を View から排除できる）
* 効果音・Return 読み上げ・自動読み上げが **独立した Feature** に分離し、**互いに直接依存しない**
* 新機能追加が **`InputScreenComposer` のリストに1行足す** ことで完結しやすく、OCP に沿った変更パスが明確になる
* `Audio/`・`Speech/` は **他コンテキストでも再利用しやすい** 汎用モジュールとして残せる

### デメリット・トレードオフ
* ファイル数と初期配線のボイラープレートが増える
* Combine の購読を **Composition ルート（Composer）が生存している間** 保持する必要があり、`SceneDelegate` 等で Composer を保持するなど **ライフサイクル管理** に注意が必要になる
* イベント粒度は「今いる3機能」に最適化しており、**全く異種の入力ソース**を同一ストリームに載せる場合は、別のイベント型や画面の分割を検討する必要がある

## Compliance
* View は **表示と UI イベントの中継** に限定し、音再生・読み上げ・ビジネスルールを持たないこと
* ViewModel は **イベント発行・表示状態・`clearText` 等の公開 API** に責務を限定し、UIKit・`AVFoundation` に依存しないこと
* 新しい入力連動の副作用は **`InputScreenFeaturePlugin` 実装クラスを追加**し、`InputScreenComposer` で `bind` すること。**既存 Feature や ViewModel を機能追加のために広範に書き換えない**こと
* イベントケースの命名は **SVO・`user` 主語** を維持し、`TextAreaInputEvent` の意味的拡張は **Feature 要件から逆算** して最小限にすること
* **`ViewController` クラス名を Storyboard から変更しない**こと
