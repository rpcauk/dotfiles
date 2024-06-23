# Setup history
mkdir -p "$XDG_CACHE_HOME/zsh"
HISTFILE="$XDG_CACHE_HOME/zsh/history"
HISTSIZE=1000000000
SAVEHIST=1000000000
export HISTTIMEFORMAT="[%F %T] "
setopt extended_history hist_find_no_dups inc_append_history share_history

# Set options
setopt auto_cd pushd_ignore_dups
setopt extendedglob globdots nomatch
setopt appendhistory bang_hist
setopt interactive_comments
setopt long_list_jobs notify
setopt prompt_cr prompt_subst
setopt beep combining_chars zle

# Enables zsh vi editing modes
bindkey -v

# Add to path
# export PATH=$PATH:$BIN_DIR

# Load aliases
source "$XDG_CONFIG_HOME/shell/aliasrc"

# Set prompt and enable colors
autoload -Uz colors && colors
autoload -Uz vcs_info                  #
zstyle ':vcs_info:git:*' formats ' %b' # Add git branch to prompt
precmd() { vcs_info }                  #
PROMPT=$'\n''%F{blue}%~%f%F{green}${vcs_info_msg_0_}%f'$'\n''%(?.%F{green}.%F{red})❯%f '

# function preexec() {
#   timer=$(($(date +%s%0N)/1000000))
# }

# function precmd() {
#   if [ $timer ]; then
#     now=$(($(date +%s%0n)/1000000))
#     elapsed=$(($now-$timer))
#     export rprompt="%f{cyan}${elapsed}ms%f "
#     unset timer
#   fi
# }

# Simplifies prompt for scrollback
zle-line-init() {
  emulate -L zsh
  [[ $CONTEXT == start ]] || return 0
  while true; do
    zle .recursive-edit
    local -it ret=$?
    [[ $ret == 0 && $KEYS == $'\4' ]] || break
    [[ -o ignore_eof ]] || exit 0
  done
  local saved_prompt=$PROMPT
  local saved_rprompt=$RPROMPT
  PROMPT='%F{yellow}❯%f '
  RPROMPT=''
  # RPROMPT=' [%D{%L:%M:%S}]'
  zle .reset-prompt
  PROMPT=$saved_prompt
  RPROMPT=$saved_rprompt
  if (( ret )); then
    zle .send-break
  else
    zle .accept-line
  fi
  return ret
}

zle -N zle-line-init

# Move zsh completion dump
autoload -Uz compinit
for dump in $ZCOMPDUMP(N.mh+24); do
    compinit -i -u -d $ZCOMPDUMP
done
compinit -C -d $ZCOMPDUMP

# Enable tab completion
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh

# Enable syntax highlighting
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
