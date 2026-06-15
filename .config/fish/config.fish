# Homebrew を PATH 先頭へ（/usr/bin の Apple git より優先させる）
# --path: PATH を直接操作。永続しないので config.fish 側で毎起動設定する
if test -x /opt/homebrew/bin/brew
    fish_add_path --path --move --prepend /opt/homebrew/bin /opt/homebrew/sbin
end

if status is-interactive
# Commands to run in interactive sessions can go here

# starship プロンプトを初期化
if type -q starship
    starship init fish | source
end

# fzf シェル統合（Ctrl+R 履歴 / Ctrl+T ファイル / Alt+C ディレクトリ移動）
if type -q fzf
    # 配色は ghostty テーマ "Material Design Colors" に統一
    set -gx FZF_DEFAULT_OPTS "\
--color=bg+:#2a363b,bg:#1d262a,spinner:#59ffd1,hl:#fc669b \
--color=fg:#e7ebed,header:#fc669b,info:#37b6ff,pointer:#59ffd1 \
--color=marker:#5cf19e,fg+:#e7ebed,prompt:#37b6ff,hl+:#fc669b \
--color=border:#435b67"

    # 候補生成は fd を使う（.git を除外しつつ隠しファイルも対象、シンボリックリンク追従）
    if type -q fd
        set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'
        # Ctrl+T: ファイル/ディレクトリ挿入（`code ` の後に押せばパス補完になる）
        set -gx FZF_CTRL_T_COMMAND 'fd --hidden --follow --exclude .git'
        # Alt+C: fzf で cd（ディレクトリのみ）
        set -gx FZF_ALT_C_COMMAND 'fd --type d --hidden --follow --exclude .git'
    end

    # Ctrl+T: ファイルは bat、ディレクトリは eza tree でプレビュー
    set -gx FZF_CTRL_T_OPTS "\
--preview 'test -d {} && eza --tree --level=2 --color=always --icons=always -a {} || bat --style=numbers --color=always --line-range :200 {}' \
--preview-window 'right:60%'"
    # Alt+C: cd 先の中身を eza tree でプレビュー
    set -gx FZF_ALT_C_OPTS "\
--preview 'eza --tree --level=2 --color=always --icons=always -a {}' \
--preview-window 'right:60%'"

    # Tab 補完（fzf_complete）: 候補1個なら即確定 / 0個なら即終了 / 複数なら fzf
    set -gx FZF_COMPLETION_OPTS "--select-1 --exit-0"

    fzf --fish | source
end

# git-wt シェル統合（`git wt <branch>` での worktree 切替 cd と補完を有効化）
if type -q git-wt
    git wt --init fish | source
end

# 起動時に tmux を自動で立ち上げる（tmux 内・VSCode 内では除く）
if type -q tmux; and test -z "$TMUX"; and test "$TERM_PROGRAM" != vscode
    # main が既に他のウィンドウで使用中（クライアント接続済み）なら独立した新規セッション、
    # そうでなければ "main" にアタッチ（無ければ作成）
    if tmux has-session -t main 2>/dev/null; and test (tmux list-clients -t main 2>/dev/null | count) -gt 0
        # 独立セッション。ウィンドウを閉じて detach したら自動破棄し、溜めない。
        # 注: destroy-unattached は未アタッチのセッションに設定した瞬間に破棄されるため、
        # client-attached フックでアタッチ後に有効化する（main には影響させない）。
        set -l sname win-$fish_pid
        tmux new-session -d -s $sname
        tmux set-hook -t $sname client-attached "set-option -t $sname destroy-unattached on"
        exec tmux attach -t $sname
    else
        exec tmux new-session -A -s main
    end
end
end

# Added by `nodenv init` on Fri Jun  5 11:36:48 JST 2026
status --is-interactive; and nodenv init - --no-rehash fish | source
