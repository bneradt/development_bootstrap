# ~/.bashrc: executed by bash(1) for non-login shells.
# vim:softtabstop=4:shiftwidth=4:et:ai
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

for path in \
    $HOME/bin \
    $HOME/ssh_bin \
    $HOME/local/bin
do
    export PATH=$path:$PATH
done

GDBHISTFILE=${HOME}/.gdbhistory

export EDITOR=nvim
export MANPAGER='nvim +Man!'
export MANWIDTH=999


# Make the command line act like vi.
set -o vi

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# don't put duplicate lines in the history. See bash(1) for more options
# don't overwrite GNU Midnight Commander's setting of `ignorespace'.
export HISTCONTROL=$HISTCONTROL${HISTCONTROL+,}ignoredups
# ... or force ignoredups and ignorespace
export HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
#[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# git completion file.
if [ -f /usr/local/etc/bash_completion ]
then
    source /usr/local/etc/bash_completion
elif [ -f ${HOME}/.git-completion.bash ]
then
    source ${HOME}/.git-completion.bash
fi

# Similarly, make sure the git-prompt is sourced as well.
if [ ! -f /usr/local/etc/bash_completion ]
then
    [ -f ${HOME}/.git-prompt.sh ] && source ${HOME}/.git-prompt.sh
fi

export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWDIRTYSTATE=true
export GIT_PS1_SHOWSTASHSTATE=true
export GIT_PS1_SHOWUNTRACKEDFILES=true
export GIT_PS1_SHOWUPSTREAM="verbose"
export GIT_PS1_HIDE_IF_PWD_IGNORED=true
export GIT_PS1_SHOWCOLORHINTS=true

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
    xterm-256color) color_prompt=yes;;
esac

# I use a dark background, so this makes dir listings easier on the eyes
export LS_COLORS='di=01;34'

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    # DEFINE THE COMMAND PROMPT
    RED="\e[0;31m"
    BLUE="\e[0;36m"
    YELLOW="\e[0;33m"
    PURPLE="\e[0;35m"
    DEFAULT_TERM_COLOR="\e[0m"

    if [ -f "/.dockerenv" -o -f "/run/.containerenv" ]; then
        PS1="${BLUE}[${PURPLE}\$? ${YELLOW}\t${BLUE} \u@\h${DEFAULT_TERM_COLOR}${RED}-docker${DEFAULT_TERM_COLOR} ${PURPLE}\$(__git_ps1 ) ${RED}\w${BLUE}]${DEFAULT_TERM_COLOR}\n\$ "
    else
        PS1="${BLUE}[${PURPLE}\$? ${YELLOW}\t${BLUE} \u@\h${DEFAULT_TERM_COLOR} ${PURPLE}\$(__git_ps1 ) ${RED}\w${BLUE}]${DEFAULT_TERM_COLOR}\n\$ "
    fi
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h \w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h \w\a\]$PS1"
    ;;
*)
    ;;
esac

# Source the aliases file
[ -f ${HOME}/.aliases ] && source ${HOME}/.aliases

# tmux bash completion.
[ -f ${HOME}/.tmux-completion.bash ] && source ${HOME}/.tmux-completion.bash

# Django bash completion.
[ -f ${HOME}/.django-completion.bash ] && . ${HOME}/.django-completion.bash
