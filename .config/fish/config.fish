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

# 起動時に herdr へアタッチ（herdr 内・VSCode 内では除く）
if type -q herdr; and test -z "$HERDR_ENV"; and test "$TERM_PROGRAM" != vscode
    exec herdr
end
end

# Added by `nodenv init` on Fri Jun  5 11:36:48 JST 2026
status --is-interactive; and nodenv init - --no-rehash fish | source
