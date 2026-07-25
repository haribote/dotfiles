---
name: exoc-review
description: "ローカル LLM サーバー (exocortex) にコードレビューを依頼する時に使う。作業中リポジトリの snapshot を Windows の GPU マシンへ送り、指摘を受け取る。「ローカルでレビューして」「exocortex でレビュー」などの依頼で発動する。"
user-invocable: true
allowed-tools: "Bash(git:*), Bash(tar:*), Bash(curl:*), Bash(mktemp:*), Bash(rm:*), Bash(ssh:*), Bash(pkill:*)"
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

```bash
ssh exocortex "wsl -d exocortex -- /bin/true"
pkill -f "11435:127.0.0.1:11435"
ssh -f -N -o ExitOnForwardFailure=yes -L 11435:127.0.0.1:11435 exocortex

root=$(git rev-parse --show-toplevel)
tmp=$(mktemp -d)
tar --no-mac-metadata -czf "$tmp/snapshot.tgz" -C "$root" \
  --null -T <(git -C "$root" ls-files -z --cached --others --exclude-standard) .git
curl -sS --fail-with-body \
  -F 'params={"language":"typescript"}' \
  -F "snapshot=@$tmp/snapshot.tgz;type=application/gzip" \
  http://localhost:11435/review
rm -rf "$tmp"
pkill -f "11435:127.0.0.1:11435"
```

3. 返った JSON の `comments` をそのまま提示する。取捨選択はユーザーが行う。
   `meta.droppedContextFiles` が 0 でなければ、予算に収めるため一部の context が落ちたことを添える。

4. ローカル LLM の指摘は誤りを含みうる。明らかに誤っているものは根拠を添えて指摘する。

## うまくいかないとき

`curl` が接続を拒否されたら、ほぼディストロが停止している。
idle が続くと WSL の VM ごと落ちるため、手順 2 の先頭で起こしている。
それでも失敗する場合は `ssh exocortex "wsl -l -v"` で `Running` を確認してから張り直す。

レビューが失敗したときは、`curl` が本文を出すのでそれを読んで伝える。

- `413 context_too_large`：差分が大きすぎる。`base` を近いコミットにするなどで対象を絞る
- `502 invalid_model_output`：モデルが schema に合う JSON を返さなかった。大きな入力で起きやすい。対象を絞って再試行する
- `504 inference_timeout`：推論が 300 秒に収まらなかった。同じく対象を絞る

いずれも入力を小さくすると通ることが多い。
サーバーが入力に確保する上限は 20480 トークンで、思考の分を差し引いた残りである。

トンネルを閉じ忘れたときは `pkill -f "11435:127.0.0.1:11435"` で閉じる。
