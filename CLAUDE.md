# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 概要

macOS 向けの個人 dotfiles。ビルド・テスト・lint の仕組みはない。リポジトリのルートを `$HOME` のミラーとして扱い、各ファイルを `$HOME` 配下の同じパスに配置（手動）して使う。リポジトリ自体は `ghq` で `~/Sites` 以下に管理される前提（`.gitconfig` の `ghq.root` 参照）。

ファイルを編集したら、対応する `$HOME` の実ファイルへ反映しないと挙動は変わらない（自動同期の仕組みはない）。

## 構成

- **fish** (`.config/fish/`)
  - `config.fish`: starship プロンプト初期化、fzf シェル統合（Ctrl-R 履歴 / Ctrl-T ファイル / Ctrl-O ディレクトリ移動）、起動時に herdr へアタッチ（herdr 内・VSCode 内は除外し、`herdr` を attach-or-create で起動）、nodenv 初期化。Homebrew と同様に `~/.local/bin`（`leaf` 等 Homebrew 非管理の単体バイナリの配置先）を毎起動 PATH へ追加し、`$EDITOR` に `nvim` を設定する。
  - `conf.d/`: fzf 関連のキーバインド（`fzf_cd_keybind`=Ctrl-O, `fzf_tab_complete`=Tab, `ghq_fzf_keybind`=Ctrl-G）。`config.fish` の `fzf --fish` で定義される widget に bind しているため、読み込み順序に依存する。
  - `functions/`: `ghq_fzf`（ghq リポジトリを fzf 選択して cd）、`ll`/`ls`（eza ラッパ）。
  - プラグインマネージャは使っていない（旧 fisherman 構成は廃止）。
- **ghostty** (`.config/ghostty/config`): フォント `UDEV Gothic NF`、テーマ `Material Design Colors`。pane/tab/zoom/copy 操作は herdr が prefix（`Ctrl+a`）キーで自前処理するため ghostty 側のキー橋渡しは基本持たないが、`Cmd+T`/`Cmd+Shift+T`/`Cmd+Option+T`/`Cmd+W` の4つだけ `text:` アクションで herdr へ直接チョードを送出するブリッジを持つ（`.config/herdr/config.toml` の直接バインドと対で機能する）。`Cmd+Shift+N` は ghostty ネイティブの新規ウィンドウ。
- **herdr** (`.config/herdr/config.toml`): ワークスペース/タブ/ペイン・エージェント管理ツールの設定。prefix は `[keys] prefix = "ctrl+a"` で上書きし、pane/tab/zoom 操作や copy mode（`prefix+[`→`v` 選択→`y` でクリップボードへ）は herdr 既定キーで運用する（split は `new_cwd = "follow"` 既定で親の cwd を継承）。ghostty の Cmd ショートカット橋渡し用の直接チョードと、`Cmd+W` 用の状態依存クローズスクリプト（`.config/herdr/scripts/herdr-cmd-w.sh`）も追加済み。テーマ・トースト通知・UI 表示・キー設定のみ追跡し、セッション状態（`session.json`）とログ（`herdr-server.log`／`herdr-client.log`）は `.gitignore` で除外する。Claude Code の SessionStart フック（`~/.claude/hooks/herdr-agent-state.sh`）と連携してエージェント状態を herdr へ通知する（フック実体は `~/.claude/hooks/` 配下でマシンローカル・追跡外）。
- **nvim** (`.config/nvim/`): [LazyVim](https://github.com/LazyVim/LazyVim) の [starter](https://github.com/LazyVim/starter) をベースに導入（Neovim >= 0.11.2 が必要）。追跡対象は `init.lua`・`lua/config/*`・`lua/plugins/*`・`lazy-lock.json`（プラグインのバージョン固定）・`stylua.toml`・`.neoconf.json`・`lazyvim.json`（`:LazyExtras` の選択状態・news 既読状態）のみで、starter 同梱の `README.md`/`LICENSE`/`.gitignore` は削除済み（追跡しない）。colorscheme は [material.nvim](https://github.com/marko-cerovac/material.nvim) の "Deep Ocean" スタイル（`lua/plugins/colorscheme.lua` で `opts.colorscheme = "material-deep-ocean"`）で、ghostty の配色とは独立している。プラグイン実体・parser・キャッシュは `~/.local/share|state|cache/nvim`（repo 外）に置かれ `.config/nvim/` 配下には出ない。pane 間の移動は herdr のキーバインドに一本化し、nvim 側の pane ナビゲーション連携（`herdr.nvim` 等）は入れない。nvim split 内の移動は Vim 既定（`Ctrl-w h/j/k/l`）に任せる。Claude Code との連携も nvim 隣の herdr pane で `claude` を起動する運用のみで、nvim 側プラグインは追加しない。
- **leaf** (`.config/leaf/`): ターミナル Markdown プレビューア。herdr pane で `leaf -w <file>.md` を起動し、Claude Code や nvim が書いた Markdown（`PLAN.md` 等）をライブプレビューする運用。`Ctrl+E` で `config.toml` の `editor` に設定したエディタ（`nvim +{$line}`、対象行へジャンプ）を開き、戻ると自動リロードする。brew formula が無いため `install.sh`（`~/.local/bin/leaf` にバイナリ配置、`leaf --update` で更新）で導入し `.Brewfile` の対象外。`config.toml`（`theme`・`editor` 設定）と `material-deep-ocean.toml`（material.nvim の Deep Ocean パレットに合わせたカスタムテーマ、ghostty とは独立）を追跡する。
- **starship** (`.config/starship.toml`): 2 行構成プロンプト。Nerd Font グリフ前提。
- **tig** (`.tigrc`): git 操作を tig 上で完結させる大量のカスタムキーバインド。差分表示に **delta**、GitHub 連携（`;` `w`）に **gh** を使う。
- **gh** (`.config/gh/config.yml`): 設定のみ。認証情報 (`hosts.yml`) は `.gitignore` で除外。
- **git** (`.gitconfig`, `.gitignore_global`)
- **zsh** (`.zprofile`, `.zshrc`): fish へ移行する前のログインシェル設定（brew shellenv / PATH のみ）。
- **Homebrew** (`.Brewfile`): インストール済みの CLI ツール・GUI アプリ・フォントの一覧（`brew bundle --global` の既定パス `~/.Brewfile` のミラー）。`brew bundle dump --describe --no-vscode` で再生成する。VS Code 拡張は意図的に含めない。
- **Claude Code** (`.claude/`): 追跡対象は下記のみ（`.gitignore` は whitelist 方式: `.claude/*` を無視し、各エントリを per-entry で再 include）。
  - `CLAUDE.md`、`settings.json`（permissions allowlist・SessionStart フック・`enabledPlugins`）
  - `agents/tdd-expert`（サブエージェント）
  - `skills/commit`、`skills/japanese-tech-writing`、`skills/typescript-conventions`（skill 実体）
  - `skills/herdr`、`skills/find-skills`（`.agents/skills/` への相対 symlink。クロスエージェント共用）
  - plugins・ログ・キャッシュ・セッション・`settings.local.json` は追跡しない。plugins 実体は各マシンで `claude plugin install` または起動時に取得し、`settings.json` の `enabledPlugins` で宣言のみ管理する。
  - `~/.agents` を本 repo の `.agents` への symlink にすると、`find-skills` インストーラや他エージェントが同じ実体を共有できる。

## ブートストラップ（新しい Mac での再現手順）

1. Homebrew をインストールする。
2. このリポジトリの各ファイルを `$HOME` 配下の同じパスに配置する（`.Brewfile` → `~/.Brewfile` を含む）。
3. `brew bundle --global` で `~/.Brewfile` のツール・アプリ・フォントを一括インストールする。
4. neovim を Brewfile 経由で導入後、LazyVim starter を導入する（`git clone https://github.com/LazyVim/starter ~/.config/nvim` → `rm -rf ~/.config/nvim/.git` → starter 同梱の `README.md`/`LICENSE`/`.gitignore` を削除 → `nvim` を起動し初回の Lazy 同期を待つ）。同期後の `~/.config/nvim` がリポジトリの `.config/nvim/`（`init.lua`・`lua/config/*`・`lua/plugins/*`・`lazy-lock.json`・`stylua.toml`・`.neoconf.json`・`lazyvim.json`）と一致することを確認する。
5. fish をデフォルトシェルにする（`echo /opt/homebrew/bin/fish | sudo tee -a /etc/shells; chsh -s /opt/homebrew/bin/fish`）。
6. Node は **最新の LTS 版**を nodenv で入れてグローバル既定にする（`nodenv install --list` で最新 LTS を確認 → `nodenv install <version>` → `nodenv global <version>`）。バージョンは固定しない。
7. `gh auth login` で GitHub 認証を行う（`hosts.yml` は追跡していないため各マシンで実施）。
8. leaf を導入する（`curl -fsSL https://raw.githubusercontent.com/RivoLink/leaf/main/scripts/install.sh | sh` で `~/.local/bin/leaf` に配置。fish の PATH 追加は `config.fish` 側で毎起動行われるため追加設定不要）。

## 横断的な約束ごと

- 配色は ghostty テーマ **"Material Design Colors"** に統一されている。fish の `FZF_*` 配色、`starship.toml`、herdr の `.config/herdr/config.toml` の `[theme.custom]` の3箇所が同じ HEX 値（例: bg `#1d262a` / 青 `#37b6ff`）を共有しているので、色を変えるときはこの3箇所を揃える。nvim（material.nvim の Deep Ocean）と leaf（`.config/leaf/material-deep-ocean.toml`）はこのパレットとは独立した配色を採用しており、同期対象ではない。
- 依存コマンド: `starship`, `fzf`, `fd`, `eza`, `bat`, `delta`, `gh`, `ghq`, `jq`, `nodenv`, `rg`, `nvim`, `leaf`。未インストールでも該当機能が無効になるだけで致命的には壊れない作りにしてある（`leaf` のみ `.Brewfile` 対象外で `install.sh` 導入）。

## 注意点

- `.gitignore` で `fish_variables`（fish が生成するマシン固有状態）と `gh/hosts.yml`（認証トークン）を除外している。これらはコミットしない。
- `.gitconfig` の `user.email` は公開用のダミーアドレス。実アドレスを入れない。
- コミットメッセージは **Conventional Commits** 形式（`<type>(<scope>): <subject>`）に従う。subject は**英語**・命令形・小文字始まり・末尾ピリオドなし。絵文字は使わない。
