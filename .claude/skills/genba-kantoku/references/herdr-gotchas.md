# herdr CLI の実際の仕様

herdr の skill 文書（`herdr --skill` / 同梱の skill 定義）に書かれているコマンド表記と、実際にインストールされているバイナリの挙動にズレがあることがある。**複雑な操作の前に必ず `herdr <subcommand> --help` で現物を確認する**。以下は実際に踏んだ食い違い。

## `herdr worktree create` は新しい workspace を作る

「この tab の新しい pane」ではなく、**新しい workspace**（独立した tab 群）を作る。pane/tab ID ではなく workspace ID が新規発行される。

```bash
herdr worktree create --workspace <ID> --branch <name> --base main --path .claude/worktree/<worktree-name> --label "<label>" --no-focus
```

- `--workspace <ID>` と `--cwd <PATH>` は排他。両方渡すと `Exit code 2` になる。
- `--path` は必ず指定する。省略すると herdr のデフォルト位置に作られ、Claude Code 自身が worktree を作るときのディレクトリ規則（リポジトリ直下の `.claude/worktree/<worktree-name>`）とズレる。
- 戻り値の JSON に `result.root_pane.pane_id` と `result.workspace.workspace_id` が入っている。以降の `herdr pane` / `herdr agent` 呼び出しには `pane_id` を使う。
- ユーザーが「今の tab に pane を追加して」のように指示していた場合、実際の挙動（workspace 単位の分離）と食い違う。一度確認を取ってから進めるのが安全（AskUserQuestion で選択肢を示すとよい）。手動で「同じ tab 内の pane」にしたい場合は、`git worktree add` を自分で実行してから `herdr pane split --direction right|down` で pane を追加する代替手順がある。

## 待機コマンドは `herdr pane wait-output`

skill 文書に出てくる `herdr wait output` という表記は古い。実際のサブコマンド階層は `herdr pane wait-output`。

```bash
herdr pane wait-output <PANE_ID> --regex "<パターン>" --timeout 180000
```

`--match` はリテラル部分一致、`--regex` は正規表現。`npm ci` の完了待ちなら `--regex "added \d+ packages|npm error|up to date"` のような形が使える。

## `herdr agent wait` の `--until` は複数回指定する

```bash
herdr agent wait <target> --until done --until blocked --timeout 3600000
```

`--until done blocked` のように1回のフラグに複数値をまとめる書き方は効かない。`blocked` も監視対象に含めるのは、helper-agent が判断に迷って止まった場合を見逃さないため。

## `herdr agent prompt` は長文をファイル経由で渡す

```bash
PROMPT=$(cat /path/to/prompt.txt)
herdr agent prompt <target> "$PROMPT"
```

改行や引用符を含む長いプロンプトを直接コマンドライン引数に埋め込むと、シェルのエスケープで壊れやすい。一度ファイルに書いてから変数へ読み込み、そのまま渡すのが安全。

## agent 起動の基本形

```bash
herdr agent start <name> --kind claude --pane <PANE_ID> -- --permission-mode auto --model claude-sonnet-5
```

`--` 以降は起動するエージェント CLI（ここでは `claude`）自身への引数。

- `--permission-mode auto` の他に、リポジトリの許容度に応じて `acceptEdits` 等も選べる（`claude --help` で `--permission-mode` の choices を確認する）。
- `--model <model>` はモデルの正式名称（`claude-sonnet-5` 等）で指定する。`sonnet` のようなエイリアスは最新モデルを指す形で解決されるため、モデル更新のたびに指す先が変わる。helper-agent の挙動を再現可能にしたいなら正式名称を使う。

## その他の実測済みコマンド

- `herdr pane run <PANE_ID> "<コマンド>"`：pane にコマンドを送って実行する（`send-text` + Enter の複合）。
- `herdr agent get <name>`：エージェントの現在状態（`agent_status` 等）を JSON で取得する。
- `herdr pane read <PANE_ID> --source recent-unwrapped --lines <N>`：pane の直近出力をテキストで取得する。ソフトラップを解消した形で読みたいときは `recent-unwrapped` を使う（`wait-output` が実際にマッチに使っているのもこの形）。
- `herdr worktree remove --workspace <ID> --force`：worktree の破棄。オプション名が違う場合があるので初回は `--help` で確認する。
