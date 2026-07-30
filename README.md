# dotfiles

macOS 向けの個人 dotfiles。リポジトリのルートを `$HOME` のミラーとして扱い、各ファイルを `$HOME` 配下の同じパスに配置して使う。

リポジトリ自体は [`ghq`](https://github.com/x-motemen/ghq) で `~/Sites` 以下に管理する前提（`.gitconfig` の `ghq.root` 参照）。ビルド・テスト・lint や自動同期の仕組みは持たない。ファイルを編集したら、対応する `$HOME` の実ファイルへ手動で反映する。

## 構成

| 対象 | パス | 概要 |
| --- | --- | --- |
| **fish** | `.config/fish/` | starship プロンプト初期化、fzf シェル統合（Ctrl-R 履歴 / Ctrl-T ファイル / Ctrl-O ディレクトリ移動 / Ctrl-G ghq）、起動時に herdr へアタッチ（herdr 内・VSCode 内は除外）、nodenv 初期化。`~/.local/bin` を PATH へ追加し `$EDITOR` に `nvim` を設定。`conf.d/` に fzf 関連キーバインド、`functions/` に `ghq_fzf` と eza ラッパ（`ll`/`ls`）。プラグインマネージャは未使用。 |
| **ghostty** | `.config/ghostty/config` | フォント `UDEV Gothic NF`、テーマ `Material Design Colors`。pane/tab の操作は herdr の prefix（`Ctrl+a`）に一本化するため、ghostty 側のキー設定は持たない。`Cmd+T`（new_tab）・`Cmd+W`（close_surface）・`Cmd+N`（new_window）は ghostty 既定のまま。 |
| **herdr** | `.config/herdr/config.toml` | ワークスペース/タブ/ペイン・エージェント管理ツールの設定。prefix は `Ctrl+a`。pane/tab/zoom と copy mode（`prefix+[`→`v`→`y`）は herdr 既定キーで運用し、既定と同じ割当は設定に書かない。独自のキーは 2 つで、`prefix+space` は `fish` を popup で開き（70% x 60%）、`prefix+a` はカレントペインの右にワークスペース幅の 26% で Claude Code を開く（`scripts/herdr-claude-pane.sh`）。追跡するのはテーマ・トースト通知・UI 表示・キー設定とスクリプトのみ。セッション状態（`session.json`）とログ（`*.log`）は `.gitignore` で除外。Claude Code の SessionStart フックと連携してエージェント状態を herdr へ通知する。 |
| **nvim** | `.config/nvim/` | [LazyVim](https://github.com/LazyVim/LazyVim) の [starter](https://github.com/LazyVim/starter) をベースに導入（Neovim >= 0.11.2 が必要）。追跡対象は `init.lua`・`lua/config/*`・`lua/plugins/*`・`lazy-lock.json`・`stylua.toml`・`.neoconf.json`・`lazyvim.json` のみ。starter 同梱の `README.md`/`LICENSE`/`.gitignore` は削除して追跡しない。colorscheme は material.nvim の "Deep Ocean"（`lua/plugins/colorscheme.lua`、ghostty とは独立）。有効な `:LazyExtras` は `lang.typescript`・`lang.markdown`・`formatting.prettier`・`lang.json`・`lang.yaml`・`lang.tailwind`・`lang.docker`・`lang.git`・`test.core`・`ai.claudecode`。Markdown プレビューは `lang.markdown`（render-markdown.nvim）でバッファ内装飾し、mermaid は markdown-preview.nvim（`<leader>cp`、ブラウザ表示）で見る。テストランナーは `test.core` に neotest-vitest adapter を追加。Claude Code とは `ai.claudecode` extra の claudecode.nvim（WebSocket 連携、キーは `<leader>a*`）で連携する。snacks.image の Kitty graphics inline 描画は herdr pane 非対応のため使わない。プラグイン実体・parser・キャッシュは repo 外（`~/.local/share|state|cache/nvim`）。pane 間の移動は herdr のキーバインドに一本化し、nvim 側の pane ナビゲーション連携は持たない。 |
| **starship** | `.config/starship.toml` | 2 行構成プロンプト。Nerd Font グリフ前提。 |
| **lazygit** | `Library/Application Support/lazygit/config.yml` | git 操作を lazygit 上で完結させる TUI。git worktree の一覧・作成・切り替え・削除を標準の worktree ビューでサポートする。lazygit は既定では `.gitconfig` の pager 設定を継承しないため、差分表示を delta にするには `git.pagers` を明示設定する必要がある（設定ファイルのパスは XDG ではなく macOS の `Application Support` 配下）。GitHub 連携（PR 作成）は `gh` 検出時に標準キーバインドで有効になり、追加設定は不要。lazygit が生成するマシン固有の実行時状態（`state.yml`：最近開いたリポジトリ、PR キャッシュ等）は `.gitignore` で除外し、`config.yml` のみ追跡する。 |
| **gh** | `.config/gh/config.yml` | 設定のみ。認証情報（`hosts.yml`）は `.gitignore` で除外。 |
| **git** | `.gitconfig`, `.gitignore_global` | delta pager・alias 等。`user.email` は公開用ダミー。 |
| **zsh** | `.zprofile`, `.zshrc` | fish 移行前のログインシェル設定（brew shellenv / PATH のみ）。 |
| **Homebrew** | `.Brewfile` | インストール済み CLI ツール・GUI アプリ・フォントの一覧（`~/.Brewfile` のミラー）。`brew bundle dump --describe --no-vscode` で再生成する。VS Code 拡張は意図的に含めない。 |
| **Claude Code** | `.claude/` | グローバル個人設定（`CLAUDE.md`）・エディタ設定（`settings.json`: permissions allowlist・SessionStart フック・有効プラグイン宣言 `enabledPlugins`）・サブエージェント（`agents/`）・skills（`skills/`）を追跡。プラグインの実体（`~/.claude/plugins/`）や会話ログ・キャッシュ・セッション等のマシン固有/機密データは除外し、settings.json で宣言のみ追跡する。 |
| **共用 skill** | `.agents/` | クロスエージェント共用 skill（`herdr` / `find-skills`）の実体。`.claude/skills/` からはリポジトリ内相対の symlink（`../../.agents/skills/...`）で参照し、マシン固有の絶対パスを埋め込まない。`~/.agents` も本 repo の `.agents` への symlink にすると、find-skills インストーラや他エージェントが同じ実体を共有する。インストーラ生成の `.skill-lock.json`（マシン固有）は除外する。 |

## ブートストラップ（新しい Mac での再現手順）

1. [Homebrew](https://brew.sh/) をインストールする。
2. このリポジトリの各ファイルを `$HOME` 配下の同じパスに配置する（`.Brewfile` → `~/.Brewfile` を含む）。
3. `brew bundle --global` で `~/.Brewfile` のツール・アプリ・フォントを一括インストールする。
4. neovim をインストール後（手順 3 の `brew bundle --global` に含む）、LazyVim starter を導入する。
   ```sh
   git clone https://github.com/LazyVim/starter ~/.config/nvim
   rm -rf ~/.config/nvim/.git
   nvim   # 初回起動で lazy.nvim がプラグインを同期する
   ```
   同期完了後、`~/.config/nvim` 配下がこのリポジトリの `.config/nvim/`（`init.lua`・`lua/config/*`・`lua/plugins/*`・`lazy-lock.json`・`stylua.toml`・`.neoconf.json`・`lazyvim.json`）と一致していることを確認する（starter 同梱の `README.md`/`LICENSE`/`.gitignore` は削除する）。C コンパイラ（`nvim-treesitter` 用）は Xcode Command Line Tools で充足するため、未導入なら `xcode-select --install` を先に実行する。
5. fish をデフォルトシェルにする。
   ```sh
   echo /opt/homebrew/bin/fish | sudo tee -a /etc/shells
   chsh -s /opt/homebrew/bin/fish
   ```
6. Node は最新の LTS 版を nodenv で入れてグローバル既定にする（バージョンは固定しない）。
   ```sh
   nodenv install --list   # 最新 LTS を確認
   nodenv install <version>
   nodenv global <version>
   ```
7. `gh auth login` で GitHub 認証を行う（`hosts.yml` は追跡していないため各マシンで実施）。
8. Claude Code のプラグインを導入する。`settings.json` は有効化を宣言するだけで実体（`~/.claude/plugins/`）は追跡していないため、各マシンで取得する。
   - **対話起動の場合**: `~/.claude/settings.json` 配置後に `claude` を起動すると、公式マーケットプレイス（`claude-plugins-official`）が自動登録され、宣言済みプラグインが導入される。
   - **非対話で再現する場合**: 以下を実行する。
     ```sh
     claude plugin marketplace add anthropics/claude-plugins-official
     claude plugin install skill-creator@claude-plugins-official
     claude plugin install typescript-lsp@claude-plugins-official
     claude plugin install frontend-design@claude-plugins-official
     claude plugin install superpowers@claude-plugins-official
     ```
9. （任意）クロスエージェント共用 skill の実体を共有する。`.claude/skills/` の `herdr` / `find-skills` symlink はリポジトリ内相対なので、`~/.claude` を配置した時点で repo 追跡下の実体（`.agents/skills/`）を指し、Claude Code だけならこの手順は不要。find-skills インストーラや他エージェントと同じ実体を共有したい場合は、`~/.agents` を本 repo の `.agents` への symlink にする。
   ```sh
   ln -s "$(ghq root)/github.com/haribote/dotfiles/.agents" ~/.agents
   ```

## 依存コマンド

`starship`, `fzf`, `fd`, `eza`, `bat`, `delta`, `gh`, `ghq`, `jq`, `nodenv`, `rg`, `nvim`, `lazygit`。

全て `.Brewfile` に含まれる。未インストールでも該当機能が無効になるだけで、致命的には壊れない作りにしてある。

## 配色

ghostty テーマ **"Material Design Colors"** に統一している。fish の `FZF_*` 配色、`starship.toml`、herdr の `.config/herdr/config.toml` の `[theme.custom]` の3箇所が同じ HEX 値（例: bg `#1d262a` / 青 `#37b6ff`）を共有しているので、色を変えるときはこの3箇所を揃える。nvim（`lua/plugins/colorscheme.lua` 経由の material.nvim "Deep Ocean"）はこのパレットとは独立した配色を採用しており、同期対象ではない。

## 注意点

- `.gitignore` で `fish_variables`（fish が生成するマシン固有状態）と `gh/hosts.yml`（認証トークン）を除外している。これらはコミットしない。
- `.claude/settings.json` は追跡対象だが、Claude Code の `/model` コマンドが書き込む `model` キーはマシン/セッション固有なのでコミットしない。
- `~/.claude/plugins/`（プラグインの実体・キャッシュ・`installed_plugins.json` 等）は `.gitignore` 対象でコミットしない。各マシンでブートストラップ手順 8 により取得する。
- `.agents/.skill-lock.json`（skill インストーラが生成するマシン固有の状態）は `.gitignore` 対象でコミットしない。`.agents/skills/` の実体のみ追跡する。
- `.gitconfig` の `user.email` は公開用のダミーアドレス。実アドレスを入れない。
- コミットメッセージは [Conventional Commits](https://www.conventionalcommits.org/) 形式（`<type>(<scope>): <subject>`）に従う。
