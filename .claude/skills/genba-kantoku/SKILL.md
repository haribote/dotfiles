---
name: genba-kantoku
description: "herdr（ターミナル型マルチプレクサ）を使い、独立して並行実行可能な複数のサブタスクを別々の git worktree・helper-agent（claude --permission-mode auto）へ並行委譲し、CI・code review・mergeまでを lead-agent として監督するワークフロー。ユーザーが「並行で進めて」「手分けして」「herdrで」「複数のPRに分けて進めて」「helper-agentに投げて」と言ったとき、あるいは独立した3件以上のサブタスク（複数ファイルへの同種の改修、複数モジュールへの並行リファクタ、複数の独立したバグ修正、複数の設計文書の並行改訂など）を1セッションで捌く必要があると判断したときは、明示の指示がなくてもこのスキルを検討すること。herdr環境（HERDR_ENV=1）かつ git リポジトリでの作業に限る。単一ファイルの変更や、2件以下で分割の恩恵が薄いタスク、herdr環境外では使わない。"
---

# 現場監督（genba-kantoku）

herdr を使い、lead-agent（このセッション）が複数の helper-agent（別 git worktree、`claude --permission-mode auto`）へ独立した作業を並行委譲し、レビュー・統合まで監督するワークフロー。「現場監督」という名は、別々の worktree に散らばる helper-agent を lead-agent が巡回して検品・承認する構図から取った。

## このパターンが向くとき

- サブタスクが3件以上あり、それぞれ独立した領域を触る（互いにブロックしない、あるいは依存関係が明確で並行実行グループ「Wave」に分けられる）
- 各サブタスクが単独で PR として完結できる
- 各サブタスクに CI・レビューなどの検証ステップがあり、逐次実行だと待ち時間が積み重なる

**サブタスク＝PR の単位は、ファイル数ではなくドメイン・関心事で切る。**
1ファイル1PRを既定にしない。同じ関心（同じ設計判断の波及、同じ機能の一部）を表す複数ファイルは、たとえ跨ぐドメインが違っても1つのサブタスク・1本のPRにまとめる。
逆に、同じファイルでも独立した複数の関心が混在するなら、コミットを分けて記述するなど別の手段を検討し、無理に1PRへ押し込めない。
「向くとき」の判断基準である3件以上・独立という条件は、ファイル数ではなく関心の数で数える。

向かないとき：
- タスクが1〜2件で、分割のオーバーヘッド（worktree 作成・依存関係インストール・プロンプト設計）が見合わない
- サブタスク同士が密結合していて、並行化すると同一ファイルへの競合編集が起きる
- herdr 環境で動いていない（`echo $HERDR_ENV` が `1` でない）

判断に迷うときは `tewake` skill（軽量委譲の判断基準）も参照する。このスキルは「委譲するか」ではなく「herdr の worktree + helper-agent で並行実行するときの型」を扱う。

## 全体の流れ

1. **事前準備**：herdr 環境の確認、リポジトリの規約把握、依存関係分析と Wave 分割
2. **Wave 単位の実行ループ**：worktree 作成 → セットアップ → helper-agent 起動 → 委譲 → 完了待ち
3. **レビューと統合**：CI 確認、code review、指摘対応（発散防止）、マージ確認、後片付け
4. 次の Wave へ、全 Wave 完了まで繰り返す

## Step 0: herdr 環境を確認する

`HERDR_ENV=1` でなければこのスキルは使えない。herdr skill をまだ読んでいなければ先に読み込み、`herdr pane list` で現在の pane / workspace 構成を把握する。

## Step 1: 事前準備

- リポジトリのビルド・テスト・lint コマンドを把握する（`package.json` の scripts、Makefile、CONTRIBUTING.md、CLAUDE.md 等）。各 helper-agent のプロンプトに含める材料になる。
- コミット規約・PR 規約・**merge 方式**を確認する（CONTRIBUTING.md、CLAUDE.md、`docs/commit.md` 相当のファイル、あるいは過去の PR の merge 履歴を `gh pr list --state merged --limit 5` 等で見る）。squash・rebase・merge commit のどれを使うかはリポジトリごとに異なるので決め打ちしない。
- まずドメイン・関心事でサブタスクを切り出す（例：「型定義の変更」「呼び出し側3ファイルの追従」「テストの更新」ではなく、「ある設計判断とその波及全体」のように、意味のまとまりで切る）。そのうえで、サブタスク同士の依存関係を洗い出し、並行可能なグループ（Wave）に分ける。
  - **1つのファイルを複数の helper-agent が同時に触らないことだけを保証する**（衝突回避のための制約であり、1サブタスク＝1ファイルを要求するものではない）。あるサブタスクが複数ファイルにまたがってよい。同じファイルに触れる複数の関心が別々のサブタスクに分かれてしまう場合は、依存関係を直列（同じ Wave に置かない）にするか、いっそ1つのサブタスクへ統合できないか見直す。
  - 依存関係の判断基準：あるサブタスクの内容が、別のサブタスクの確定した成果（main に merge された内容）を必要とするか。
  - Wave 内は完全並行、Wave 間は直列（前 Wave の全 PR が main 済みであることを次 Wave 開始の条件にする）。
- 規模が大きい（Wave が2つ以上、あるいは PR が5本を超える）場合は、Wave 構成とファイル分担を一度ユーザーに提示し承認を得てから着手する。plan mode があればそこで確定させるとよい。

## Step 2: Wave 単位の実行ループ

各 Wave で、並行させるサブタスクの数だけ以下を行う。**並行実行するため、複数の Bash 呼び出しを同一メッセージ内で発行する**（順に1つずつ呼ぶと並行にならない）。

1. **worktree 作成**：`herdr worktree create --workspace <ID> --branch <branch-name> --base main --path .claude/worktree/<worktree-name> --label "<label>" --no-focus`
   - `--path` は Claude Code 自身が worktree を作る際と同じディレクトリ規則（リポジトリ直下の `.claude/worktree/<worktree-name>`）に揃える。省略しない。
   - 重要な注意点は `references/herdr-gotchas.md` を参照。特に、これは「今の tab の新しい pane」ではなく**新しい workspace**を作る。ユーザーが特定の見た目（同一 tab 内の pane）を指示していた場合は、実際の挙動が異なることを一度確認する。
2. **依存関係インストール**：`herdr pane run <PANE> "npm ci"`（プロジェクトに応じたコマンドに置き換える）→ `herdr pane wait-output <PANE> --regex "<完了を示す正規表現>" --timeout 180000` で完了を待つ。
3. **helper-agent 起動**：`herdr agent start <name> --kind claude --pane <PANE> -- --permission-mode auto --model claude-sonnet-5`
   - モデルは正式名称（`claude-sonnet-5` 等）で指定する。エイリアス（`sonnet` 等）は将来のモデル更新で指す先が変わりうるため使わない。
4. **プロンプト送信**：`references/prompt-template.md` の雛形に沿って、担当範囲・厳守事項・完了条件を明記した長文プロンプトを送る。改行を含む長文は一時ファイルに書いてシェル変数へ読み込んでから `herdr agent prompt <name> "$PROMPT"` で送る。
5. **完了待ち**：`herdr agent wait <name> --until done --until blocked --timeout <十分な時間>`（`--until` は状態ごとに繰り返す。`--until done blocked` という1引数指定は効かない）。
   - `done` が返っても実際にはまだバックグラウンドタスクの完了待ちで止まっていることがある。詳細は `references/troubleshooting.md`。

## Step 3: レビューと統合

各 PR について：

1. **CI 確認と code review を並行実行**する（CI ポーリングと `/code-review` を同時に走らせ、両方の完了を待つ）。
2. **指摘対応ループ**（詳細は `references/troubleshooting.md` の「レビューの発散を防ぐ」）：同一ファイル・その PR の改訂範囲内の指摘のみ修正し、別ファイルへの言及は issue やチケットへ申し送る。2〜3 周で収束しなければ、それ以上は申し送りに切り替えて打ち切る。
3. CI green・レビュー収束を確認したら、**ユーザーに個別に確認を取ってから** merge する。merge 方式（squash / rebase / merge commit）は Step 1 で確認したリポジトリの慣例に従う。承認は使い回さない（PR が10本あれば10回確認する。CLAUDE.md の「新しい破壊的操作ごとに確認する」原則どおり）。
4. merge 後、worktree を削除する（`herdr worktree remove --workspace <ID> --force`）。
5. その Wave の全 PR が main 済みであることを確認してから次の Wave へ進む。次の Wave の worktree を切る前に、ローカルの `main` が最新であることも確認する（`git pull` または `git fetch` + HEAD 確認）。

## 責務分担の原則

- **helper-agent（worktree 内）が自律的に行う**：実装・コミット・push・draft PR 作成・PR 番号確定後のドキュメント更新・`gh pr ready`・レビュー由来の申し送りコメント投稿。
- **lead-agent（このセッション）が担当し、都度ユーザー確認を挟む**：merge、worktree 削除。

理由：helper-agent の作業は worktree 内に閉じ被害範囲が限定されるが、merge と worktree 削除はリポジトリ共有状態・後続 Wave の起点を書き換える操作で、失敗すれば連鎖する。この線引きは最初から helper-agent へのプロンプトに明記する（「merge は行わない」）。

## 想定外の発見への対応

作業中に「計画していなかった別ファイルの矛盾」や「既に merge 済みの過去の PR 自体の誤り」が見つかることがある。これは並行作業の副産物として珍しくない。見つけたら、その場で手を広げず、まず lead-agent が内容を整理してユーザーに報告し、対応範囲（今回のスコープに含めるか、申し送りに留めるか）を確認してから動く。詳細は `references/troubleshooting.md` の「後続の作業で前の作業の誤りが発覚する」。

## 参照

- `references/herdr-gotchas.md`：herdr CLI の実際の仕様。着手前に一度目を通す。
- `references/prompt-template.md`：helper-agent へ渡すプロンプトの雛形と埋め込み変数。
- `references/troubleshooting.md`：実務でつまずきやすい点（`agent_status` の誤検知、push し忘れ、公開操作の確認プロンプト、レビューの発散防止、後続作業での過去PRの誤り発覚）。
