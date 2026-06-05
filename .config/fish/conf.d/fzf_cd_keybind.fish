status is-interactive || exit

# Ctrl+O で fzf によるディレクトリ移動（macOS では Option=Alt が既定で効かないため
# Alt+C の代わりに Ctrl+O を使う）。fzf-cd-widget は config.fish の `fzf --fish` で定義される
bind ctrl-o fzf-cd-widget
bind -M insert ctrl-o fzf-cd-widget
