"#####表示設定#####
set title "編集中のファイル名を表示
colorscheme hybrid
syntax on "コードの色分け
set tabstop=4 "インデントをスペース4つ分に設定
set smartindent "オートインデント

"#####検索設定#####
set ignorecase "大文字/小文字の区別なく検索する
set smartcase "検索文字列に大文字が含まれている場合は区別して検索する
set wrapscan "検索時に最後まで行ったら最初に戻る

"--------------------
"" 基本的な設定
"--------------------
"新しい行のインデントを現在行と同じにする
set autoindent 
"タブの代わりに空白文字を指定する
set expandtab
"インクリメンタルサーチを行う
set incsearch
""行番号を表示する
set number
"閉括弧が入力された時、対応する括弧を強調する
set showmatch
""新しい行を作った時に高度な自動インデントを行う
set smarttab

"#####NeoBundle#####
"--------------------
"" 基本的な設定
"--------------------
if has('vim_starting')
        set nocompatible            " Be iMproved
        " Required:
        set runtimepath+=~/.vim/bundle/neobundle.vim/
endif
" Required:
call neobundle#begin(expand('~/.vim/bundle'))
" Let NeoBundle manage NeoBundle
" Required:
NeoBundleFetch 'Shougo/neobundle.vim'
" My Bundles here:
NeoBundle 'Shougo/unite.vim'
NeoBundle 'Shougo/neomru.vim'
NeoBundle 'scrooloose/nerdtree'
NeoBundle 'nathanaelkane/vim-indent-guides'
NeoBundle 'bronson/vim-trailing-whitespace'
call neobundle#end()
" Required:
filetype plugin indent on
" If there are uninstalled bundles found on startup,
" this will conveniently prompt you to install them.
NeoBundleCheck
"--------------------
"" Unite.vim
"--------------------
" 入力モードで開始する
let g:unite_enable_start_insert=1
" バッファ一覧
noremap <C-P> :Unite buffer<CR>
" ファイル一覧
noremap <C-N> :Unite -buffer-name=file file<CR>
" 最近使ったファイルの一覧
noremap <C-Z> :Unite file_mru<CR>
" sourcesを「今開いているファイルのディレクトリ」とする
noremap :uff :<C-u>UniteWithBufferDir file -buffer-name=file<CR>
" ウィンドウを分割して開く
au FileType unite nnoremap <silent> <buffer> <expr> <C-J> unite#do_action('split')
au FileType unite inoremap <silent> <buffer> <expr> <C-J> unite#do_action('split')
" ウィンドウを縦に分割して開く
au FileType unite nnoremap <silent> <buffer> <expr> <C-K> unite#do_action('vsplit')
au FileType unite inoremap <silent> <buffer> <expr> <C-K> unite#do_action('vsplit')
" ESCキーを2回押すと終了する
au FileType unite nnoremap <silent> <buffer> <ESC><ESC> :q<CR>
au FileType unite inoremap <silent> <buffer> <ESC><ESC> <ESC>:q<CR>
"--------------------
"" vim-indent-guides
"--------------------
let g:indent_guides_enable_on_vim_startup = 1

