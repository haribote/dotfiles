---
name: pr
description: "PRのライフサイクル全体をゲート付きで管理する。PR作成、レビュー対応、マージ、ポストマージまでの一連のワークフローを強制する。PRを作りたい、レビュー対応したい、マージしたい、といった場面で使用する。"
user-invocable: true
allowed-tools: "Bash(git:*), Bash(gh:*), Bash(glab:*)"
---

# PR Lifecycle

PRのライフサイクルをゲート付きで管理する。各ステップにはゲート条件がある。ゲートを通過しないまま次に進むな。

`$ARGUMENTS` でフェーズを指定できる: `create`, `review`, `merge`。省略時は現在のPR状態を判定して適切なフェーズから開始する。

## コンテキスト予算

生コマンド出力をそのままコンテキストに流さない。

- diff・JSON・チェック結果は、まず `--stat` 等の要約形を見る。全文が要るときだけ対象を絞って取得する。
- 大きい出力（full diff、レビュースレッド JSON）は context-mode（`ctx_execute` / `ctx_batch_execute`）で digest 化し、要約だけ受け取る。context-mode が無ければ対象を絞った取得で代替する。

## Phase 1: Create（PR作成）

### ゲート条件
- テストが通過していること（プロジェクトのテストコマンドを実行して確認）
- lintが通過していること

### 実行

#### 1. 状況把握

```bash
git status --short
git rev-parse --abbrev-ref HEAD
git diff --stat HEAD
```

`--stat` で変更の形（ファイル・増減行）を把握する。commit message / PR body を書くのに意味的内容が要る場合:

- **context-mode あり**: `git diff HEAD` を `ctx_execute`(language: "shell") に流し、digest（per-file の hunk header `@@`、追加/削除された関数・見出し行、代表 hunk）だけを `console.log` で受け取る。生 diff はサンドボックスに留まる。
- **無し**: 変更ファイルごとに `git diff HEAD -- <path>` を必要な分だけ読む。全ファイルを一括 `git diff HEAD` しない。

#### 2. ブランチ作成（必要な場合）

`main`ブランチ上に未コミットの変更がある場合、新しいブランチを作成する。差分の内容から適切なブランチ名を提案する（例: `feature/add-user-auth`, `fix/handle-null-errors`）。

```bash
git checkout -b <branch-name>
```

#### 3. コミット

- コミットメッセージは `/commit` skill の規約に従う（Conventional Commits 形式・subject 規約・絵文字禁止・AI co-author credits 不含・リポジトリ固有ルール優先）。

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
2. 未解決のレビューコメントがあれば、各スレッドを確認し、修正 or 返信で対応してから解決する
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
