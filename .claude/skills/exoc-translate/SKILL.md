---
name: exoc-translate
description: "ローカル LLM サーバー (exocortex) に日英翻訳を依頼する時に使う。日本語から英語、英語から日本語へ翻訳する。「ローカルで翻訳して」「exocortex で翻訳」などの依頼で発動する。"
user-invocable: true
allowed-tools: "Bash(curl:*), Bash(jq:*), Bash(ssh:*), Bash(pkill:*)"
---

# exoc-translate

ローカル LLM サーバー (exocortex) に日英翻訳を依頼する。

## 前提

`ssh exocortex` が通ること。
通らなければその旨を伝えて終了する。設定を推測して直そうとしない。

API は Windows の loopback にだけ publish されており、LAN からは届かない。
SSH トンネルを張って `http://localhost:11435` を叩く。
認証は SSH の公開鍵に委ねているため、リクエストに認証ヘッダは付けない。

## 手順

1. 翻訳方向を決める。`from` と `to` は必須で、`ja` と `en` のどちらかである。
   依頼文から明らかでなければユーザーに聞く。方向を推測しない。

2. ディストロを起こしてトンネルを張り、POST する。
   `FROM` と `TO` には手順 1 で決めた方向を入れる。下の値は日本語から英語への例にすぎない。
   本文の JSON への埋め込みは `jq` に任せる。改行や引用符を自前でエスケープしない。

```bash
ssh exocortex "wsl -d exocortex -- /bin/true"
pkill -f "11435:127.0.0.1:11435"
ssh -f -N -o ExitOnForwardFailure=yes -L 11435:127.0.0.1:11435 exocortex

FROM=ja
TO=en
jq -n --arg text "$TEXT" --arg from "$FROM" --arg to "$TO" \
  '{text: $text, from: $from, to: $to}' |
curl -sf -H 'Content-Type: application/json' --data-binary @- \
  http://localhost:11435/translate
pkill -f "11435:127.0.0.1:11435"
```

3. 返る JSON は `{"text": "..."}` である。
   訳文はそのまま提示する。自分で訳し直したり、体裁を整えたりしない。

## うまくいかないとき

`curl` が接続を拒否されたら、ほぼディストロが停止している。
idle が続くと WSL の VM ごと落ちるため、手順 2 の先頭で起こしている。
それでも失敗する場合は `ssh exocortex "wsl -l -v"` で `Running` を確認してから張り直す。

トンネルを閉じ忘れたときは `pkill -f "11435:127.0.0.1:11435"` で閉じる。
