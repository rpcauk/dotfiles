#!/bin/bash

export EDITOR=vim
export GIT_EDITOR=vim
export PAGER=less
unset LESSOPEN

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
export ZCOMPDUMP="$XDG_CACHE_HOME/zsh/zcompdump"
export BIN_DIR="$HOME/.local/bin"
export PROJECTS_DIR="$HOME/projects"

export BROWSER="$BIN_DIR/firefox"

# fzf config
export FZF_DEFAULT_COMMAND="rg --files --hidden --follow -g '!{.cache,.rodeo,.git,.kube,limbo,shared,venv}/' -g '!.local/{share,state}'/"
export FZF_DEFAULT_OPTS="--height=40% --layout=reverse -m --border=rounded --no-separator --no-scrollbar"
