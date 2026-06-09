# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 概要

macOS 向けの個人 dotfiles。ビルド・テスト・lint の仕組みはない。リポジトリのルートを `$HOME` のミラーとして扱い、各ファイルを `$HOME` 配下の同じパスに配置（手動）して使う。リポジトリ自体は `ghq` で `~/Sites` 以下に管理される前提（`.gitconfig` の `ghq.root` 参照）。

ファイルを編集したら、対応する `$HOME` の実ファイルへ反映しないと挙動は変わらない（自動同期の仕組みはない）。

## 構成

- **fish** (`.config/fish/`)
  - `config.fish`: starship プロンプト初期化、fzf シェル統合（Ctrl-R 履歴 / Ctrl-T ファイル / Ctrl-O ディレクトリ移動）、git-wt 統合（`git wt --init fish`。`if type -q git-wt` ガード付きで未インストール時は no-op）、起動時の tmux 自動アタッチ（`main` セッション。tmux 内・VSCode 内は除外）、nodenv 初期化。
  - `conf.d/`: fzf 関連のキーバインド（`fzf_cd_keybind`=Ctrl-O, `fzf_tab_complete`=Tab, `ghq_fzf_keybind`=Ctrl-G）。`config.fish` の `fzf --fish` で定義される widget に bind しているため、読み込み順序に依存する。
  - `functions/`: `ghq_fzf`（ghq リポジトリを fzf 選択して cd）、`ll`/`ls`（eza ラッパ）。
  - プラグインマネージャは使っていない（旧 fisherman 構成は廃止）。
- **tmux** (`.tmux.conf`): tmux 3.6+ 前提。prefix は Ctrl-a。ghostty 連携のため CSI u 拡張キーや truecolor を明示設定。
- **ghostty** (`.config/ghostty/config`): フォント `UDEV Gothic NF`、テーマ `Material Design Colors`。Cmd 系キーを tmux のプレフィックスシーケンスに変換するキーバインドを持つ（`.tmux.conf` のバインドと対で機能する）。
- **starship** (`.config/starship.toml`): 2 行構成プロンプト。Nerd Font グリフ前提。
- **tig** (`.tigrc`): git 操作を tig 上で完結させる大量のカスタムキーバインド。差分表示に **delta**、GitHub 連携（`;` `w`）に **gh** を使う。
- **gh** (`.config/gh/config.yml`): 設定のみ。認証情報 (`hosts.yml`) は `.gitignore` で除外。
- **git** (`.gitconfig`, `.gitignore_global`)
- **zsh** (`.zprofile`, `.zshrc`): fish へ移行する前のログインシェル設定（brew shellenv / PATH のみ）。
- **Homebrew** (`.Brewfile`): インストール済みの CLI ツール・GUI アプリ・フォントの一覧（`brew bundle --global` の既定パス `~/.Brewfile` のミラー）。`brew bundle dump --describe --no-vscode` で再生成する。VS Code 拡張は意図的に含めない。
- **Claude Code** (`.claude/`): グローバル個人設定 (`CLAUDE.md`)・エディタ設定 (`settings.json`: permissions allowlist・Stop フック)・サブエージェント (`agents/`: `code-critic`, `tdd-expert`)・skills (`skills/`: `five-whys`, `pr-lifecycle`, `worktree`, `address-pr-review`, `call-code-critic`, `critic-design-review`, `critic-implementation-review`) を追跡する。会話ログ・キャッシュ・セッション・`settings.local.json` 等のマシン固有/機密データは `.gitignore` の whitelist で除外している（`.claude/*` を無視し、上記の許可エントリ＝ `CLAUDE.md` / `settings.json` / `agents/` / `skills/` だけを再 include）。`address-pr-review/fetch-unresolved-threads.sh` は実行ビット付き（`100755`）で追跡する。

## ブートストラップ（新しい Mac での再現手順）

1. Homebrew をインストールする。
2. このリポジトリの各ファイルを `$HOME` 配下の同じパスに配置する（`.Brewfile` → `~/.Brewfile` を含む）。
3. `brew bundle --global` で `~/.Brewfile` のツール・アプリ・フォントを一括インストールする。
4. fish をデフォルトシェルにする（`echo /opt/homebrew/bin/fish | sudo tee -a /etc/shells; chsh -s /opt/homebrew/bin/fish`）。
5. Node は **最新の LTS 版**を nodenv で入れてグローバル既定にする（`nodenv install --list` で最新 LTS を確認 → `nodenv install <version>` → `nodenv global <version>`）。バージョンは固定しない。
6. `gh auth login` で GitHub 認証を行う（`hosts.yml` は追跡していないため各マシンで実施）。

## 横断的な約束ごと

- 配色は ghostty テーマ **"Material Design Colors"** に統一されている。fish の `FZF_*` 配色、`.tmux.conf` のステータスライン、`starship.toml` が同じ HEX 値（例: bg `#1d262a` / 青 `#37b6ff`）を共有しているので、色を変えるときは 3 箇所を揃える。
- 依存コマンド: `starship`, `fzf`, `fd`, `eza`, `bat`, `delta`, `gh`, `ghq`, `nodenv`, `tmux`, `git-wt`。未インストールでも該当機能が無効になるだけで致命的には壊れない作りにしてある。

## 注意点

- `.gitignore` で `fish_variables`（fish が生成するマシン固有状態）と `gh/hosts.yml`（認証トークン）を除外している。これらはコミットしない。
- `.gitconfig` の `user.email` は公開用のダミーアドレス。実アドレスを入れない。
- コミットメッセージは **Conventional Commits** 形式（`<type>(<scope>): <subject>`）に従う。subject は**英語**・命令形・小文字始まり・末尾ピリオドなし。絵文字は使わない。
