# dotfiles

macOS 向けの個人 dotfiles。リポジトリのルートを `$HOME` のミラーとして扱い、各ファイルを `$HOME` 配下の同じパスに配置して使う。

リポジトリ自体は [`ghq`](https://github.com/x-motemen/ghq) で `~/Sites` 以下に管理する前提（`.gitconfig` の `ghq.root` 参照）。ビルド・テスト・lint や自動同期の仕組みは持たない。ファイルを編集したら、対応する `$HOME` の実ファイルへ手動で反映する。

## 構成

| 対象 | パス | 概要 |
| --- | --- | --- |
| **fish** | `.config/fish/` | starship プロンプト初期化、fzf シェル統合（Ctrl-R 履歴 / Ctrl-T ファイル / Ctrl-O ディレクトリ移動 / Ctrl-G ghq）、起動時の tmux 自動アタッチ（`main` セッション。tmux 内・VSCode 内は除外）、nodenv 初期化。`conf.d/` に fzf 関連キーバインド、`functions/` に `ghq_fzf` と eza ラッパ（`ll`/`ls`）。プラグインマネージャは未使用。 |
| **tmux** | `.tmux.conf` | tmux 3.6+ 前提。prefix は `Ctrl-a`。ghostty 連携のため CSI u 拡張キーや truecolor を明示設定。 |
| **ghostty** | `.config/ghostty/config` | フォント `UDEV Gothic NF`、テーマ `Material Design Colors`。Cmd 系キーを tmux のプレフィックスシーケンスに変換するキーバインドを持つ。 |
| **herdr** | `.config/herdr/config.toml` | ワークスペース/タブ/ペイン・エージェント管理ツールの設定。テーマ・トースト通知・UI 表示のみ追跡。セッション状態（`session.json`）とログ（`*.log`）は `.gitignore` で除外。 |
| **starship** | `.config/starship.toml` | 2 行構成プロンプト。Nerd Font グリフ前提。 |
| **tig** | `.tigrc` | git 操作を tig 上で完結させるカスタムキーバインド。差分表示に [delta](https://github.com/dandavison/delta)、GitHub 連携に `gh` を使う。 |
| **gh** | `.config/gh/config.yml` | 設定のみ。認証情報（`hosts.yml`）は `.gitignore` で除外。 |
| **git** | `.gitconfig`, `.gitignore_global` | delta pager・alias 等。`user.email` は公開用ダミー。 |
| **zsh** | `.zprofile`, `.zshrc` | fish 移行前のログインシェル設定（brew shellenv / PATH のみ）。 |
| **Homebrew** | `.Brewfile` | インストール済み CLI ツール・GUI アプリ・フォントの一覧（`~/.Brewfile` のミラー）。VS Code 拡張は意図的に含めない。 |
| **Claude Code** | `.claude/` | グローバル個人設定（`CLAUDE.md`）・エディタ設定（`settings.json`: permissions allowlist・Stop / SessionStart フック・有効プラグイン宣言 `enabledPlugins` とマーケットプレイス宣言 `extraKnownMarketplaces`）・サブエージェント（`agents/`）・skills（`skills/`）を追跡。プラグインの実体（`~/.claude/plugins/`）や会話ログ・キャッシュ・セッション等のマシン固有/機密データは除外し、settings.json で宣言のみ追跡する。 |

## ブートストラップ（新しい Mac での再現手順）

1. [Homebrew](https://brew.sh/) をインストールする。
2. このリポジトリの各ファイルを `$HOME` 配下の同じパスに配置する（`.Brewfile` → `~/.Brewfile` を含む）。
3. `brew bundle --global` で `~/.Brewfile` のツール・アプリ・フォントを一括インストールする。
4. fish をデフォルトシェルにする。
   ```sh
   echo /opt/homebrew/bin/fish | sudo tee -a /etc/shells
   chsh -s /opt/homebrew/bin/fish
   ```
5. Node は最新の LTS 版を nodenv で入れてグローバル既定にする（バージョンは固定しない）。
   ```sh
   nodenv install --list   # 最新 LTS を確認
   nodenv install <version>
   nodenv global <version>
   ```
6. `gh auth login` で GitHub 認証を行う（`hosts.yml` は追跡していないため各マシンで実施）。
7. Claude Code のプラグインを導入する。`settings.json` は有効化を宣言するだけで実体（`~/.claude/plugins/`）は追跡していないため、各マシンで取得する。
   - **対話起動の場合**: `~/.claude/settings.json` 配置後に `claude` を起動すると、公式マーケットプレイス（`claude-plugins-official`）は自動登録され、`context-mode` マーケットプレイスは trust プロンプトで承認すると導入される。
   - **非対話で再現する場合**: 以下を実行する。
     ```sh
     claude plugin marketplace add anthropics/claude-plugins-official
     claude plugin marketplace add mksglu/context-mode
     claude plugin install context-mode@context-mode
     claude plugin install skill-creator@claude-plugins-official
     claude plugin install typescript-lsp@claude-plugins-official
     claude plugin install frontend-design@claude-plugins-official
     claude plugin install superpowers@claude-plugins-official
     ```

## 依存コマンド

`starship`, `fzf`, `fd`, `eza`, `bat`, `delta`, `gh`, `ghq`, `jq`, `nodenv`, `rg`, `tmux`。

いずれも `.Brewfile` に含まれる。未インストールでも該当機能が無効になるだけで、致命的には壊れない作りにしてある。

## 配色

ghostty テーマ **"Material Design Colors"** に統一している。fish の `FZF_*` 配色、`.tmux.conf` のステータスライン、`starship.toml` が同じ HEX 値（例: bg `#1d262a` / 青 `#37b6ff`）を共有しているので、色を変えるときは 3 箇所を揃える。

## 注意点

- `.gitignore` で `fish_variables`（fish が生成するマシン固有状態）と `gh/hosts.yml`（認証トークン）を除外している。これらはコミットしない。
- `~/.claude/plugins/`（プラグインの実体・キャッシュ・`installed_plugins.json` 等）は `.gitignore` 対象でコミットしない。各マシンでブートストラップ手順 7 により取得する。
- `.gitconfig` の `user.email` は公開用のダミーアドレス。実アドレスを入れない。
- コミットメッセージは [Conventional Commits](https://www.conventionalcommits.org/) 形式（`<type>(<scope>): <subject>`）に従う。
