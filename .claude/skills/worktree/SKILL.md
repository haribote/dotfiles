---
name: worktree
description: "git worktree操作（git-wt使用）- 一覧・作成・切替・削除を自在に実行する。ブランチ切替、並行作業、PRレビュー用チェックアウト、worktree管理に使用する。「別ブランチで作業したい」「worktreeを整理したい」「並行して作業したい」といった要求にも対応する。"
user-invocable: true
allowed-tools: "Bash(git:*)"
---

# Worktree Skill

git-wtを使用してgit worktreeを効率的に操作する。

## 使用条件

- git-wtがインストール済みであること
- gitリポジトリ内で実行すること

## 基本コマンド

```bash
# 一覧表示
git wt

# 切替/作成（存在しなければ作成）
git wt <branch>

# 特定のcommit/branchから作成
git wt <branch> <start-point>

# 安全削除（マージ済みのみ）
git wt -d <branch>

# 強制削除
git wt -D <branch>
```

## 重要フラグ

| フラグ | 用途 |
|-------|------|
| `--copyignored` | .gitignore対象ファイル（.env等）をコピー |
| `--copyuntracked` | 未追跡ファイルをコピー |
| `--copymodified` | 未コミット変更をコピー |
| `--hook "cmd"` | 作成後にコマンド実行（npm install等） |

## 実行手順

### 1. 状況把握（常に最初に実行）

```bash
git wt
git status --short
```

### 2. ユーザー要求に応じた操作

**新規作業開始:**
```bash
git wt feat/new-feature
# または環境ファイル付き
git wt feat/new-feature --copyignored
```

**PR/MRレビュー:**
```bash
git fetch origin pull/<PR_NUMBER>/head:review-pr-<PR_NUMBER>
git wt review-pr-<PR_NUMBER>
```

**作業終了・削除:**
```bash
git wt -d <branch>  # マージ済み確認後
```

### 3. 注意事項

- 未コミット変更がある状態で切替しない（先にstash/commit）
- Shell統合により切替後は自動でcdされる
- worktreeの作成場所は原則的に `<workspace root>/.wt` 以下
- わからない場合は `git wt --help` を参照
