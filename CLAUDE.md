# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 概要

macOS 向けの個人 dotfiles。ビルド・テスト・lint の仕組みはない。リポジトリのルートを `$HOME` のミラーとして扱い、各ファイルを `$HOME` 配下の同じパスに配置（手動）して使う。リポジトリ自体は `ghq` で `~/Sites` 以下に管理される前提（`.gitconfig` の `ghq.root` 参照）。

ファイルを編集したら、対応する `$HOME` の実ファイルへ反映しないと挙動は変わらない（自動同期の仕組みはない）。

## 構成

- **fish** (`.config/fish/`)
  - `config.fish`: starship プロンプト初期化、fzf シェル統合（Ctrl-R 履歴 / Ctrl-T ファイル / Ctrl-O ディレクトリ移動）、起動時に herdr へアタッチ（herdr 内・VSCode 内は除外し、`herdr` を attach-or-create で起動）、nodenv 初期化。
  - `conf.d/`: fzf 関連のキーバインド（`fzf_cd_keybind`=Ctrl-O, `fzf_tab_complete`=Tab, `ghq_fzf_keybind`=Ctrl-G）。`config.fish` の `fzf --fish` で定義される widget に bind しているため、読み込み順序に依存する。
  - `functions/`: `ghq_fzf`（ghq リポジトリを fzf 選択して cd）、`ll`/`ls`（eza ラッパ）。
  - プラグインマネージャは使っていない（旧 fisherman 構成は廃止）。
- **ghostty** (`.config/ghostty/config`): フォント `UDEV Gothic NF`、テーマ `Material Design Colors`。pane/tab/zoom/copy 操作は herdr が prefix（`Ctrl+a`）キーで自前処理するため ghostty 側のキー橋渡しは持たない。キーバインドは ghostty ネイティブの `Cmd+Shift+N`（新規ウィンドウ）のみ。
- **herdr** (`.config/herdr/config.toml`): ワークスペース/タブ/ペイン・エージェント管理ツールの設定。テーマ・トースト通知・UI 表示のみ追跡し、セッション状態（`session.json`）とログ（`herdr-server.log`／`herdr-client.log`）は `.gitignore` で除外する。Claude Code の SessionStart フック（`~/.claude/hooks/herdr-agent-state.sh`）と連携してエージェント状態を herdr へ通知する（フック実体は `~/.claude/hooks/` 配下でマシンローカル・追跡外）。
- **starship** (`.config/starship.toml`): 2 行構成プロンプト。Nerd Font グリフ前提。
- **tig** (`.tigrc`): git 操作を tig 上で完結させる大量のカスタムキーバインド。差分表示に **delta**、GitHub 連携（`;` `w`）に **gh** を使う。
- **gh** (`.config/gh/config.yml`): 設定のみ。認証情報 (`hosts.yml`) は `.gitignore` で除外。
- **git** (`.gitconfig`, `.gitignore_global`)
- **zsh** (`.zprofile`, `.zshrc`): fish へ移行する前のログインシェル設定（brew shellenv / PATH のみ）。
- **Homebrew** (`.Brewfile`): インストール済みの CLI ツール・GUI アプリ・フォントの一覧（`brew bundle --global` の既定パス `~/.Brewfile` のミラー）。`brew bundle dump --describe --no-vscode` で再生成する。VS Code 拡張は意図的に含めない。
- **Claude Code** (`.claude/`): グローバル個人設定 (`CLAUDE.md`)・エディタ設定 (`settings.json`: permissions allowlist・Stop フック・SessionStart フック〔context-mode cache heal〕・有効プラグイン宣言 `enabledPlugins`〔context-mode + 公式 4 つ〕とサードパーティ製マーケットプレイス宣言 `extraKnownMarketplaces`〔context-mode〕)・サブエージェント (`agents/`: `tdd-expert`)・skills (`skills/`: `five-whys`, `commit`, `pr-lifecycle`, `typescript-conventions`) を追跡する。プラグインの実体（`~/.claude/plugins/` 配下の `marketplaces/`・`cache/`・`installed_plugins.json` 等）は `.gitignore` で除外し、settings.json で有効化の宣言だけを追跡する（実体は各マシンで `claude plugin install` または起動時の trust プロンプトで取得する。手順は README 参照）。会話ログ・キャッシュ・セッション・`settings.local.json` 等のマシン固有/機密データは `.gitignore` の whitelist で除外している（`.claude/*` を無視し、`CLAUDE.md` / `settings.json` を再 include。`agents/` と `skills/` はディレクトリ全体ではなく、宣言済みの個別エントリ＝ `tdd-expert` と上記4 skill だけを per-entry で再 include する。これによりプラグインや手動インストールで入ったサードパーティ製の skill / agent は自動的に追跡対象外になる）。

## ブートストラップ（新しい Mac での再現手順）

1. Homebrew をインストールする。
2. このリポジトリの各ファイルを `$HOME` 配下の同じパスに配置する（`.Brewfile` → `~/.Brewfile` を含む）。
3. `brew bundle --global` で `~/.Brewfile` のツール・アプリ・フォントを一括インストールする。
4. fish をデフォルトシェルにする（`echo /opt/homebrew/bin/fish | sudo tee -a /etc/shells; chsh -s /opt/homebrew/bin/fish`）。
5. Node は **最新の LTS 版**を nodenv で入れてグローバル既定にする（`nodenv install --list` で最新 LTS を確認 → `nodenv install <version>` → `nodenv global <version>`）。バージョンは固定しない。
6. `gh auth login` で GitHub 認証を行う（`hosts.yml` は追跡していないため各マシンで実施）。

## 横断的な約束ごと

- 配色は ghostty テーマ **"Material Design Colors"** に統一されている。fish の `FZF_*` 配色と `starship.toml` が同じ HEX 値（例: bg `#1d262a` / 青 `#37b6ff`）を共有しているので、色を変えるときは 2 箇所を揃える。
- 依存コマンド: `starship`, `fzf`, `fd`, `eza`, `bat`, `delta`, `gh`, `ghq`, `jq`, `nodenv`, `rg`。未インストールでも該当機能が無効になるだけで致命的には壊れない作りにしてある。

## 注意点

- `.gitignore` で `fish_variables`（fish が生成するマシン固有状態）と `gh/hosts.yml`（認証トークン）を除外している。これらはコミットしない。
- `.gitconfig` の `user.email` は公開用のダミーアドレス。実アドレスを入れない。
- コミットメッセージは **Conventional Commits** 形式（`<type>(<scope>): <subject>`）に従う。subject は**英語**・命令形・小文字始まり・末尾ピリオドなし。絵文字は使わない。
