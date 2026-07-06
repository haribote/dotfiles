---
name: commit
description: "git commit を作成する時に使う。Conventional Commits 形式（type(scope): subject）・英語・命令形・小文字始まり・末尾ピリオドなし・50〜72 文字目安・1 行完結、絵文字禁止・AI co-author 禁止のコミットメッセージを作成してコミットする。コミットメッセージを書く場面で発動する。"
user-invocable: true
allowed-tools: "Bash(git diff:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*)"
---

# コミット規約

git commit を作成するときに従う規約。これがコミットメッセージ規約の単一の source of truth。

## 優先順位

- リポジトリ固有のコミットルール（`CONTRIBUTING.md`, `.gitmessage` 等）があれば**それを優先**する。
- なければ以下の **Conventional Commits** に従う。

## 形式

`<type>(<scope>): <subject>`

主な type:

- `feat`: 新機能
- `fix`: バグ修正
- `docs`: ドキュメント
- `style`: 整形（挙動を変えない）
- `refactor`: リファクタリング
- `test`: テスト
- `chore`: 雑務
- `perf`: パフォーマンス改善

## subject の規約

- **英語**・**命令形**・**小文字始まり**・**末尾ピリオドなし**。
- **50〜72 文字以内**を目安にする。
- **1 行で完結させる**。試行錯誤の経緯や実装の詳細は書かない。

## 破壊的変更

- `feat!:` のように `!` を付けるか、フッターに `BREAKING CHANGE:` を書く。

## 禁止事項

- **絵文字は使わない**。
- **AI co-author credits は含めない**。
- **箇条書きで実装詳細を列挙しない**（冗長なコミットメッセージを避ける）。

## 実行フロー

コミットする前に以下のステップを踏む。

### Step 1: ステージ内容を確認する

```bash
git diff --cached
```

変更の性質（新機能・バグ修正・リファクタ・ドキュメントなど）と影響範囲を把握する。

### Step 2: 直近の commit 履歴でスタイルを確認する

```bash
git log --oneline -10
```

言語・構造・プレフィックス・文体の傾向を確認する。履歴が本スキルの規約と一致しない場合でも、本スキルの規約を優先する。

### Step 3: コミットして報告する

分析結果をもとに、シンプルで簡潔なコミットメッセージを作成してコミットする。
コミット後、実行したメッセージをユーザーに報告する。

```bash
git commit -m "<type>(<scope>): <subject>"
```
