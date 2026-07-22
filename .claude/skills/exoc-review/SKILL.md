---
name: exoc-review
description: "ローカル LLM サーバー (exocortex) にコードレビューを依頼する時に使う。git diff と関連ファイルを集めて Windows の GPU マシンへ送り、指摘を受け取る。「ローカルでレビューして」「exocortex でレビュー」などの依頼で発動する。"
user-invocable: true
allowed-tools: "Bash(exoc-review:*)"
---

# exoc-review

`exoc-review` コマンドを実行してレビュー結果を受け取る。

オプションは `exoc-review --help` で確認する。指定がなければ未コミットの変更をレビューする。

`EXOCORTEX_ENDPOINT` と `EXOCORTEX_TOKEN` が未設定の場合はその旨を伝えて終了する。勝手に値を推測しない。

結果はそのまま提示する。指摘の取捨選択はユーザーが行う。ローカル LLM の指摘は誤りを含みうるので、明らかに誤っているものがあれば根拠を添えて指摘する。
