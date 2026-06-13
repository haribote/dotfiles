---
name: commit
description: "git commit を作成・提案する時に使う。Conventional Commits 形式（type(scope): subject）、subject の規約（英語・命令形・小文字始まり・末尾ピリオドなし・50〜72 文字目安）、絵文字禁止、破壊的変更の feat! / BREAKING CHANGE 表記を適用する。コミットメッセージを書く場面で発動する。"
user-invocable: true
allowed-tools: "Bash(git:*)"
---

# コミット規約

git commit を作成・提案するときに従う規約。これがコミットメッセージ規約の単一の source of truth。

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
- 件名は **50〜72 文字以内**を目安にする。

## 破壊的変更

- `feat!:` のように `!` を付けるか、フッターに `BREAKING CHANGE:` を書く。

## 禁止事項

- **絵文字は使わない**。
- **AI co-author credits は含めない**。

## 実行フロー（Fail-Safe）

- 作業が一区切りしたら commit を**提案**する。実行はユーザーの確認後に行い、勝手に commit しない。

```bash
git add <paths>
git commit -m "<type>(<scope>): <subject>"
```
