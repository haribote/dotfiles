function ghq_fzf --description 'ghq で管理しているリポジトリを fzf で検索して cd（ファイル一覧をプレビュー）'
    set -l selected (ghq list --full-path | fzf \
        --query (commandline) \
        --prompt 'ghq> ' \
        --preview 'eza --tree --level=2 --color=always --icons=always -a {}' \
        --preview-window 'right:60%')
    if test -n "$selected"
        cd "$selected"
        commandline -r ''
    end
    commandline -f repaint
end
