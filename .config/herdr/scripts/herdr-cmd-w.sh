#!/usr/bin/env bash
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo "herdr-cmd-w: jq not found, aborting" >&2
  read -r -p "Press enter to close..." _ || true
  exit 1
fi

pane_id="${HERDR_ACTIVE_PANE_ID:?HERDR_ACTIVE_PANE_ID not set}"
tab_id="${HERDR_ACTIVE_TAB_ID:?HERDR_ACTIVE_TAB_ID not set}"
workspace_id="${HERDR_ACTIVE_WORKSPACE_ID:?HERDR_ACTIVE_WORKSPACE_ID not set}"

tabs_json="$(herdr tab list --workspace "$workspace_id")"
tab_count="$(jq '.result.tabs | length' <<<"$tabs_json")"
pane_count="$(jq --arg t "$tab_id" \
  '[.result.tabs[] | select(.tab_id == $t) | .pane_count][0] // 1' <<<"$tabs_json")"
workspace_count="$(herdr workspace list | jq '.result.workspaces | length')"

if [ "$pane_count" -gt 1 ]; then
  scope="pane"
elif [ "$tab_count" -gt 1 ]; then
  scope="tab"
else
  scope="workspace"
fi

if [ "$scope" = "workspace" ] && [ "$workspace_count" -eq 1 ]; then
  prompt="Close the last workspace? [y/N] "
else
  prompt="Close current $scope? [y/N] "
fi

read -r -p "$prompt" reply || reply=""
case "$reply" in
  y|Y)
    case "$scope" in
      pane) herdr pane close "$pane_id" ;;
      tab) herdr tab close "$tab_id" ;;
      workspace) herdr workspace close "$workspace_id" ;;
    esac
    ;;
  *)
    echo "cancelled"
    sleep 0.6
    ;;
esac
