# コミットメッセージ例（@commitlint/config-conventional）

## 機能追加
- `feat(map): add cluster icon for request markers`
- `feat(auth): implement JWT login`

## バグ修正
- `fix(api): return 400 when limit exceeds 100`
- `fix(ui): hide search type toggle when range is fixed`

## ドキュメント
- `docs: add container registry migration guide`
- `docs(deploy): update env vars section`

## リファクタ
- `refactor: extract useMarkerFilterContext mock in tests`
- `refactor(db): simplify migration script`

## 依存・設定
- `chore(deps): add jsdom for vitest environment`
- `chore(deps): add @opentelemetry/api to satisfy vitest peer`
- `ci: add test script to package.json`

## スタイル・その他
- `style: fix lint errors in BottomNavigationDock`
- `test: add route tests for feature-requests API`
- `build: add glob override for npm audit`

## 避ける例
- `Add login feature` → type がない
- `fix: Fixed the bug.` → 末尾のピリオド、大文字
- `Update dependencies` → `chore(deps): update dependencies` のように type を付ける
