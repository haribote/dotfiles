---
name: pr
description: "PRのライフサイクル全体をゲート付きで管理する。PR作成、レビュー対応、マージ、ポストマージまでの一連のワークフローを強制する。PRを作りたい、レビュー対応したい、マージしたい、といった場面で使用する。"
user-invocable: true
allowed-tools: "Bash(git:*), Bash(gh:*), Bash(glab:*)"
---

# PR Lifecycle

PRのライフサイクルをゲート付きで管理する。各ステップにはゲート条件がある。ゲートを通過しないまま次に進むな。

`$ARGUMENTS` でフェーズを指定できる: `create`, `review`, `merge`。省略時は現在のPR状態を判定して適切なフェーズから開始する。

## Phase 1: Create（PR作成）

### ゲート条件
- テストが通過していること（プロジェクトのテストコマンドを実行して確認）
- lintが通過していること

### 実行

#### 1. 状況把握

```bash
git status
git rev-parse --abbrev-ref HEAD
git diff HEAD
```

#### 2. ブランチ作成（必要な場合）

`main`ブランチ上に未コミットの変更がある場合、新しいブランチを作成する。差分の内容から適切なブランチ名を提案する（例: `feature/add-user-auth`, `fix/handle-null-errors`）。

```bash
git checkout -b <branch-name>
```

#### 3. コミット

- リポジトリ固有のコミットルール（CONTRIBUTING.md, .gitmessage等）を優先する
- ルールがなければConventional Commits形式を使用する
  - Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `style`, `perf`
  - Format: `type(scope): description`
- AI co-author credits は含めない

```bash
git add .
git commit -m "<commit-message>"
```

#### 4. Push + PR作成

- GitLabリポジトリの場合は `glab` を使用する
- AI co-author credits はPRタイトル・本文に含めない
- PR TEMPLATEが存在する場合（`.github/PULL_REQUEST_TEMPLATE.md`等）、そのテンプレートに従ってPR本文を作成する
- テンプレートが存在しない場合は、変更内容から適切なタイトルと説明を生成する

```bash
git push origin <branch-name>
```

PR TEMPLATEの確認（`.github/PULL_REQUEST_TEMPLATE.md`、`.github/pull_request_template.md`、`docs/pull_request_template.md`等）。存在すればテンプレートに従ってPR本文を作成する。

PR本文を`.pr-body.md`（workspace内一時ファイル）に書き出し、`--body-file`で入力する。使用後に削除する。

Write toolで`.pr-body.md`にPR本文を書き出す。

```bash
gh pr create --base main --title "<title>" --body-file .pr-body.md
```

```bash
rm .pr-body.md
```

## Phase 2: Review（レビュー対応）

### ゲート条件
- PRが作成済みであること

### 実行
1. `gh pr view` でPRの状態を確認する
2. 未解決のレビューコメントがあれば `/address-pr-review` を実行する
3. 全コメントを解決してからre-reviewを依頼する

制約:
- レビューコメントを無視してマージしようとするな
- 全コメントに対応してから次に進め

## Phase 3: Merge（マージ）

### ゲート条件
- CIが全てgreenであること: `gh pr checks` で確認
- 全レビューコメントが解決済みであること
- ユーザーからマージの承認を得ていること

### 実行
1. マージ方式（`--squash` / `--merge` / `--rebase`）を特定する。リポジトリ設定または過去のマージコミット履歴から判定する。不明ならユーザーに確認しろ
2. `gh pr merge <PR番号> --<方式>` でマージする

制約:
- ゲート条件を1つでも満たさない場合、マージしようとするな。ブロック理由を報告しろ。
- コマンド引数はリテラル遵守。指示または本手順で明示されていないフラグ・オプションを追加するな（`--delete-branch` 等）。

## Phase 4: Postmerge（ポストマージ）

Phase 3 が成功したら、指示を待たず Phase 4 を自律実行せよ。

### ゲート条件
- PRがマージ済みであること: `gh pr view <PR番号> --json state` で `MERGED` を確認

### 実行
1. main ブランチに戻る: `git switch main`
2. リモートの最新状態を取得: `git pull`

制約:
- 本手順に明示されていない操作を追加するな。ローカルブランチ削除・リモートブランチ削除・worktree 削除等はユーザーの明示指示があるまで実行しない。
