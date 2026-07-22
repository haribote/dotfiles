---
name: exoc-translate
description: "ローカル LLM サーバー (exocortex) に日英翻訳を依頼する時に使う。日本語から英語、英語から日本語へ翻訳する。「ローカルで翻訳して」「exocortex で翻訳」などの依頼で発動する。"
user-invocable: true
allowed-tools: "Bash(exoc-translate:*)"
---

# exoc-translate

`exoc-translate` コマンドを実行して訳文を受け取る。翻訳方向は `--from` と `--to` で明示する。

オプションは `exoc-translate --help` で確認する。改行を含む文章は標準入力から渡す。

`EXOCORTEX_ENDPOINT` と `EXOCORTEX_TOKEN` が未設定の場合はその旨を伝えて終了する。勝手に値を推測しない。

訳文はそのまま提示する。自分で訳し直したり、体裁を整えたりしない。
