#!/usr/bin/env bash
set -euo pipefail

# 新しいペインをワークスペース幅の 26% にする。--ratio は分割元の pane が保持する
# 割合なので、タブ全体の幅と分割元の幅から毎回逆算する。分割元がワークスペース幅の
# 半分より狭い場合は 26% を確保できないため、等分に倒す。
layout="$(herdr pane layout)"
focused_pane="$(echo "$layout" | jq -r '.result.layout.focused_pane_id')"

ratio="$(echo "$layout" | jq -r '
  .result.layout as $l
  | ($l.area.width * 0.26) as $target
  | ([$l.panes[] | select(.focused) | .rect.width][0]) as $src
  | (($src - $target) / $src)
  | if . < 0.5 then 0.5 else . end
')"

new_pane="$(herdr pane split "$focused_pane" --direction right --ratio "$ratio" --focus \
  | jq -r '.result.pane.pane_id')"

herdr agent start claude --kind claude --pane "$new_pane"
