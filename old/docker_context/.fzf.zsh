# Setup fzf
# ---------
FZF_ROOT=${HOME}/src/fzf
if [[ ! "$PATH" == *${FZF_ROOT}/bin* ]]; then
  PATH="${PATH:+${PATH}:}${FZF_ROOT}/bin"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "${FZF_ROOT}/shell/completion.zsh" 2> /dev/null

# Key bindings
# ------------
source "${FZF_ROOT}/shell/key-bindings.zsh"
