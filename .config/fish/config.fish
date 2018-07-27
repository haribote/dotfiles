set -x PATH $HOME/.anyenv/bin $PATH

set -x NDENV_ROOT $HOME/.anyenv/envs/ndenv
set -x PATH $HOME/.anyenv/envs/ndenv/bin $PATH
set -x PATH $NDENV_ROOT/shims $PATH

set -x PYENV_ROOT "$HOME/.anyenv/envs/pyenv"
set -x PATH $PATH "$HOME/.anyenv/envs/pyenv/bin"

set -x GHQ_SELECTOR peco

function fish_user_key_bindings
  bind \cg __ghq_crtl_g
  bind \cr 'peco_select_history (commandline -b)'
end

