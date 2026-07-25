---
name: exoc-translate
description: "ローカル LLM サーバー (exocortex) に日英翻訳を依頼する時に使う。日本語から英語、英語から日本語へ翻訳する。「ローカルで翻訳して」「exocortex で翻訳」などの依頼で発動する。"
user-invocable: true
allowed-tools: "Bash(curl:*), Bash(jq:*), Bash(ssh:*), Bash(pkill:*), Bash(mktemp:*), Bash(rm:*)"
---

# exoc-translate

ローカル LLM サーバー (exocortex) に日英翻訳を依頼する。

## 前提

`ssh exocortex` が通ること。
通らなければその旨を伝えて終了する。設定を推測して直そうとしない。

API は Windows の loopback にだけ publish されており、LAN からは届かない。
SSH トンネルを張って `http://localhost:11435` を叩く。
認証は SSH の公開鍵に委ねているため、リクエストに認証ヘッダは付けない。

レスポンスは NDJSON のストリームで返る。1 行 1 JSON で、行の種類は次のとおり。

- `{"delta":"..."}` — 訳文の断片。到着順に連結すると訳文になる
- `{"heartbeat":true}` — 初回 delta までの生存信号。無視してよい
- `{"done":true,"meta":{...}}` — 正常終了。これが来たら成功
- `{"error":"...","message":"..."}` — 途中失敗。訳文は不完全

モデルのロードに 30 秒ほどかかることがあり、その間は `heartbeat` だけが流れる。
**HTTP 200 は成功を意味しない。** 成功判定は `done` 行の到達で行う。

## 手順

1. 翻訳方向を決める。`from` と `to` は必須で、`ja` と `en` のどちらかである。
   依頼文から明らかでなければユーザーに聞く。方向を推測しない。

2. ディストロを起こしてトンネルを張り、ストリームをファイルに流し込む。
   `curl` はバックグラウンド（`run_in_background`）で走らせ、書き込み先を控えておく。
   `FROM` と `TO` には手順 1 で決めた方向を入れる。下の値は日本語から英語への例にすぎない。
   本文の JSON への埋め込みは `jq` に任せる。改行や引用符を自前でエスケープしない。

```bash
# Mac
ssh exocortex "wsl -d exocortex -- /bin/true"
pkill -f "11435:127.0.0.1:11435"
ssh -f -N -o ExitOnForwardFailure=yes -L 11435:127.0.0.1:11435 exocortex

OUT=$(mktemp)
echo "$OUT"

FROM=ja
TO=en
jq -n --arg text "$TEXT" --arg from "$FROM" --arg to "$TO" \
  '{text: $text, from: $from, to: $to}' |
curl -NsS --fail-with-body -H 'Content-Type: application/json' --data-binary @- \
  http://localhost:11435/translate > "$OUT"
```

3. `curl` が流している間、`$OUT` を数秒おきに読み、途中経過をユーザーに伝える。
   現時点の訳文は delta を連結して得る。`-j` は区切りを入れない指定で、delta 自体が
   改行を含むためこれを使う（`-r` は行ごとに改行が入る）。

```bash
# Mac — 現時点の訳文
jq -j 'select(.delta) | .delta' "$OUT"
```

   まだ delta が無く `heartbeat` だけなら「モデルをロード中」と伝える。

4. 終了を判定する。`curl` のバックグラウンドプロセスが終わったら `$OUT` の最終行を見る。

   - `{"done":true,...}` があれば成功。delta を連結した全文が訳文である。
   - `{"error":...}` があれば失敗。`message` を添えてその旨を伝える。訳文は不完全なので提示しない。
   - `done` も `error` も無いままストリームが切れていたら、接続断として扱う。もう一度張り直す。

   ストリームが始まる前に失敗した場合も、`$OUT` にエラーの body が入る。
   `{"error":...}` として同じように扱えばよい。

```bash
# Mac — 判定
tail -n1 "$OUT"
jq -e 'select(.done == true)' "$OUT" >/dev/null && echo done
jq -e 'select(.error)' "$OUT" >/dev/null && echo error
```

5. トンネルを閉じ、一時ファイルを消す。

```bash
# Mac
pkill -f "11435:127.0.0.1:11435"
rm -f "$OUT"
```

6. 訳文はそのまま提示する。自分で訳し直したり、体裁を整えたりしない。

## うまくいかないとき

`curl` が接続を拒否されたら、ほぼディストロが停止している。
idle が続くと WSL の VM ごと落ちるため、手順 2 の先頭で起こしている。
それでも失敗する場合は `ssh exocortex "wsl -l -v"` で `Running` を確認してから張り直す。

トンネルを閉じ忘れたときは `pkill -f "11435:127.0.0.1:11435"` で閉じる。
