status is-interactive || exit

# Tab で fzf による補完（fish の通常補完候補を fzf で絞り込む）。
# fzf_complete は config.fish の `fzf --fish` で定義される。
# 既定では Shift+Tab に bind されているが、Tab でも使えるようにする。
bind tab fzf_complete
bind -M insert tab fzf_complete
