function ll --description 'eza の長形式表示（隠しファイル含む）' --wraps eza
    eza -la --icons=always --color=always --git $argv
end
