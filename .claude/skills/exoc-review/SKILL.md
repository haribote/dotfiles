---
name: exoc-review
description: "ローカル LLM サーバー (exocortex) にコードレビューを依頼する時に使う。作業中リポジトリの snapshot を Windows の GPU マシンへ送り、指摘を受け取る。「ローカルでレビューして」「exocortex でレビュー」などの依頼で発動する。"
user-invocable: true
allowed-tools: "Bash(git:*), Bash(tar:*), Bash(curl:*), Bash(jq:*), Bash(cat:*), Bash(mktemp:*), Bash(rm:*), Bash(ssh:*), Bash(pkill:*)"
---

# exoc-review

ローカル LLM サーバー (exocortex) にコードレビューを依頼する。
作業中リポジトリの snapshot をサーバーへ送り、サーバー側で diff と関連ファイルを組んでレビューさせる。

## 前提

`ssh exocortex` が通ること。
通らなければその旨を伝えて終了する。設定を推測して直そうとしない。

API は Windows の loopback にだけ publish されており、LAN からは届かない。
SSH トンネルを張って `http://localhost:11435` を叩く。
認証は SSH の公開鍵に委ねているため、リクエストに認証ヘッダは付けない。

## 手順

1. レビュー対象を決める。指定がなければ未コミットの変更。`params` にオプションを載せる。
   - 未コミット: `{"language":"typescript"}`
   - あるブランチからの差分: `{"language":"typescript","base":"main"}`
   - ステージ済みのみ: `{"language":"typescript","staged":true}`
   - `base` と `staged` は同時に指定できない。

2. ディストロを起こしてトンネルを張り、snapshot を POST する（macOS 前提）。
   status code は fallback の判定に使うので捨てない。

```bash
ssh exocortex "wsl -d exocortex -- /bin/true"
pkill -f "11435:127.0.0.1:11435"
ssh -f -N -o ExitOnForwardFailure=yes -L 11435:127.0.0.1:11435 exocortex

root=$(git rev-parse --show-toplevel)
tmp=$(mktemp -d)
tar --no-mac-metadata -czf "$tmp/snapshot.tgz" -C "$root" \
  --null -T <(git -C "$root" ls-files -z --cached --others --exclude-standard) .git
code=$(curl -sS -o "$tmp/review.json" -w '%{http_code}' \
  -F 'params={"language":"typescript"}' \
  -F "snapshot=@$tmp/snapshot.tgz;type=application/gzip" \
  http://localhost:11435/review)
cat "$tmp/review.json"
```

3. `code` が 200 なら、返った JSON の `comments` をそのまま提示する。取捨選択はユーザーが行う。
   `meta.droppedContextFiles` が 0 でなければ、予算に収めるため一部の context が落ちたことを添える。

4. `code` が 504 なら、同じ snapshot を per-file mode で投げ直す（下の「504 のときの fallback」を見る）。
   それ以外のエラーでは投げ直さない。

5. 最後に後始末をする。fallback を回すときは、それが終わってから実行する。

```bash
rm -rf "$tmp"
pkill -f "11435:127.0.0.1:11435"
```

6. ローカル LLM の指摘は誤りを含みうる。明らかに誤っているものは根拠を添えて指摘する。

## 504 のときの fallback

`504 inference_timeout` は、モデルの thinking が暴走して 600 秒に収まらなかったことを示す。
入力の大きさではなく thinking の長さで起きるので、同じ入力で投げ直しても直らないとは限らない。

per-file mode は 1 ファイルずつ別々に推論するため、暴走したファイルだけを捨てて残りを返せる。
**変更が 2 ファイル以上あるときだけ有効である。**
1 ファイルしか変更していないなら、per-file の上限は 300 秒で whole の 600 秒より短く、通る見込みはかえって下がる。
その場合は fallback せず、`base` を近いコミットにするなどで対象を絞るよう案内する。

```bash
curl -sS -N -o "$tmp/review.ndjson" \
  -F 'params={"language":"typescript","mode":"per-file"}' \
  -F "snapshot=@$tmp/snapshot.tgz;type=application/gzip" \
  http://localhost:11435/review
```

応答は 1 行 1 JSON の ndjson になる。
`{"heartbeat":true}` は接続の維持だけが目的なので読み飛ばす。

```bash
jq -c 'select(has("comments"))' "$tmp/review.ndjson"          # ファイルごとの結果
jq -c 'select(has("file") and has("error"))' "$tmp/review.ndjson"  # 落ちたファイル
jq -c 'select(has("done"))' "$tmp/review.ndjson"              # 件数の集計
jq -c 'select(has("error") and (has("file") | not))' "$tmp/review.ndjson"  # run 全体の失敗
```

報告のしかたには、whole mode と違う注意が要る。

- `done` の `failed` と `skipped` が 0 でなければ、**何ファイルがレビューされなかったかを必ず伝える**。
  指摘が無いことと、レビューできなかったことは別である
- `{"error":"all_files_failed"}` が返ったら、1 件もレビューできていない。「問題なし」と報告してはならない
- per-file は削除されたファイルと、`language` の拡張子に合わないファイル（`.ts` `.tsx` `.js` `.jsx` 以外）を対象から外す。
  これらは `skipped` に数えられる。設定ファイルや削除の差分を見たいときは whole mode で対象を絞り直す
- `done` 行が無いまま終わっていたら、サーバーが ollama に到達できなくなった合図で、残りのファイルは未着手である

## うまくいかないとき

`curl` が接続を拒否されたら、ほぼディストロが停止している。
idle が続くと WSL の VM ごと落ちるため、手順 2 の先頭で起こしている。
それでも失敗する場合は `ssh exocortex "wsl -l -v"` で `Running` を確認してから張り直す。

レビューが失敗したときは、`curl` が本文を出すのでそれを読んで伝える。

- `413 context_too_large`：差分が大きすぎる。`base` を近いコミットにするなどで対象を絞る
- `502 invalid_model_output`：モデルが schema に合う JSON を返さなかった。大きな入力で起きやすい。対象を絞って再試行する
- `502 context_exhausted`：context window が尽きて生成が途中で切れた。原因はモデルではなく予算にあるので、対象を絞る
- `504 inference_timeout`：推論が 600 秒に収まらなかった。per-file mode に落として投げ直す（上記）

いずれも入力を小さくすると通ることが多い。
サーバーが入力に確保する上限は 20480 トークンで、思考の分を差し引いた残りである。

トンネルを閉じ忘れたときは `pkill -f "11435:127.0.0.1:11435"` で閉じる。
