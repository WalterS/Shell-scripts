############################################################
# .bashrc
#
# WS 20181220
############################################################

# Source global definitions
if [[ -f /etc/bashrc && $(uname -r|grep -c '\.el7\.') == 0 ]]; then
 . /etc/bashrc
fi

# Add local bin to path if present
if [[ -d "$HOME/bin" ]] ; then
  if [[ ! ":${PATH}:" == *":${HOME}/bin:"* ]]; then
    PATH="$HOME/bin:$PATH"
  fi
fi

# Load RVM if present
[[ -f /etc/profile.d/rvm.sh && $(uname -r|grep -c '\.el7\.') == 0 ]] && . /etc/profile.d/rvm.sh

# Clean up path, put RVM entries first
path_comb () {
  local HME IFS INDEX MY_PATH NEW_PATH P PATH_HOME PATH_NEW PATH_RVM PATH_TMP IFS

  # Safeguard if associative arrays are not implemented
  if ! declare -A PATH_HOME='()' 2>/dev/null; then
    echo "$PATH"
    return
  fi
  declare -A PATH_NEW='()'
  declare -A PATH_RVM='()'
  declare -a NEW_PATH='()'

  export IFS=$':'
  HME=~
  PATH_TMP=( ${PATH//::/:} )
  for P in "${PATH_TMP[@]}"; do
    if [[ $P =~ rvm ]]; then
      PATH_RVM["$P"]='void'
    elif [[ $P =~ ^$HME ]]; then
      PATH_HOME["$P"]='void'
    else
      PATH_NEW["$P"]='void'
    fi
  done

  unset IFS
  NEW_PATH+=("${!PATH_RVM[@]}")
  NEW_PATH+=( "${!PATH_HOME[@]}" )
  NEW_PATH+=( "${!PATH_NEW[@]}" )

  MY_PATH=$(printf "%s:" "${NEW_PATH[@]}")
  echo "${MY_PATH:0:((${#MY_PATH}-1))}"
}
export GOROOT=~/go
export PATH="$(path_comb):$GOROOT/bin"

# Remove unwanted proxy settings
unset $(env | awk -F'=' 'BEGIN {IGNORECASE=1} /_proxy/ {printf $1" "}')
if [[ -z "$IS_CLOUD" ]]; then
  if ping -nq -w 1 -c 1 169.254.169.254 >/dev/null; then
    declare -r IS_CLOUD='true'
  else
    declare -r IS_CLOUD='false'
  fi
fi

# We want CLI history
export HISTFILE=~/.bash_history
# No duplicates in history
export HISTCONTROL="ignoreboth:erasedups"
# Max history file size
export HISTFILESIZE=5000
# Max history list size
export HISTSIZE=5000
# Set window title to user@host
export PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}\007"'

# Ignore command "history" and single-letter commands"
export HISTIGNORE='history*:h *:?'

export EDITOR=vi
export PAGER="$(which less) -r"

# git-duet
export GIT_DUET_GLOBAL=true
# set git-duet to rotate between author and committer after each commit
export GIT_DUET_ROTATE_AUTHOR=1

# Set max directory depth for PS1
export PROMPT_DIRTRIM=4

# Set history format to "%n %y-%m-%d %T %command":
# export HISTTIMEFORMAT="%y-%m-%d %T "

export BOSH_ENVIRONMENT=bosh

# Append to history instead of overwriting it
shopt -s histappend
# Automagically keep track of terminal window size
shopt -s checkwinsize
shopt -s no_empty_cmd_completion
shopt -s checkhash

# Check for colour capability
PROMPT_COLOR="1;29m"

COLOR_OPT=
if [[ -x /usr/bin/tput ]] && tput setaf 1 &> /dev/null; then
  COLOR_OPT="--color=auto"
  if grep -q '/docker/' /proc/self/cgroup; then
    PROMPT_COLOR="0;32m"
  fi
  if [[ "$UID" = 0 ]]; then
    PROMPT_COLOR="1;31m"
  fi
fi

## Functions

# Run Chef
chef_run () {
[[ -f dna.json ]] && JSON='-j dna.json'
  if [[ -z "$1" ]]; then
    echo "Please provide a recipe (chef_run <cookbook_name>[::<recipe_name>])" >&2
      return 1
    fi
  chef-solo -c solo.rb $JSON -o "recipe[$1]" -l debug --force-logger 2>&1 | tee debug.txt
}

# Show if we are in a screen session
is_screen (){
  [[ -n "$STY" ]] && echo "This is a screen session"
}

# Function for process list search
# Search process list for a given string (case insensitive)
psgrep () {
  ps -ef | grep -i -- "$(sed -r 's/[[:alnum:]]/[&]/'<<<"$1")"
}

# Function for command history search
h () {
  local IFS=$'\n'
  ## Simple version with grep:
  # grep: `history | grep -i "$*"`"

  ## Extended version with awk, doesn't echo the current command line
  ## and searches only in the command column.
  # You can use "^", "$" and other regular expressions now.

  local STR="$*"
  STR=$(sed 's/\//\\\\\//g; s/\!/\\\!/g; s/\?/\\\?/g'<<<"$STR")

  # If no search expression given, just print the whole history
  if [[ -z "$STR" ]]; then
    history
    return
  fi

  local LHISTCMD=$((HISTCMD-1))
  history | awk -F'^ *[0-9]+ +' 'BEGIN {IGNORECASE=1}; $2~/'"$STR"'/' | awk '$1 !~ /'"$LHISTCMD"'/'
  # If 'HISTTIMEFORMAT="%y-%m-%d %T "' is used:
  # history | awk -F'^.*[0-9][0-9]:[0-9][0-9]:[0-9][0-9] +' 'BEGIN {IGNORECASE=1}; $2~/'"$STR"'/' | awk '$1 !~ /'"$LHISTCMD"'/'
}

# Function for pulling Git repository
# Assumes that either the current directory equals the name in ~/.gitconfig
# or that everything after "/git" corresponds to the repository path in Github
#
git_current() {
  local GITHUB='github.wdf.sap.corp'
  local REPONAME=${PWD##*/}
  local REPOBRANCH
  if ! egrep -qw 'master|release'<<<"$1"; then
    REPOBRANCH='master'
  else
    REPOBRANCH="$1"
  fi
  if ! 'grep' -q 'remote "'$REPONAME'"' ~/.gitconfig; then
    echo "$REPONAME is not defined in ~/.gitconfig, trying Github"
    REPONAME="$(sed 's#^.*git/#git@'$GITHUB':#'<<<"$(pwd)").git"
  fi

  git checkout "$REPOBRANCH" &> /dev/null
  git pull --rebase "$REPONAME" "$REPOBRANCH"
}

setproxy () {
  local NOPROXY='sap,sap.corp,sap.biz,localhost,127.0.0.1,moo-repo,169.254.169.254,bsslrepo'
  local PROXY='http://proxy.wdf.sap.corp:8080'
  local PROXIES='http_proxy https_proxy ftp_proxy'
  local MY_PROXY
  case $1 in
    "on")
      for MY_PROXY in $PROXIES; do
        export $MY_PROXY=$PROXY
      done
      export no_proxy=$NOPROXY
      echo "Proxy is switched on" ;;
    "off")
      for MY_PROXY in $PROXIES; do
        unset $MY_PROXY
      done
      echo "Proxy is switched off" ;;
    "status")
      if env|grep -q http_proxy=; then
        echo "Proxy is switched on"
      else
        echo "Proxy is switched off"
      fi ;;
    "")
      if env|grep -q http_proxy=; then
        for MY_PROXY in $PROXIES; do
          unset $MY_PROXY
        done
        echo "Proxy is switched off"
      else
        for MY_PROXY in $PROXIES; do
          export $MY_PROXY=$PROXY
        done
        export no_proxy=$NOPROXY
        echo "Proxy is switched on"
      fi ;;
    *)
      cat <<END
"setproxy" toggles proxy variables.
Usage: setproxy [on|off|status]

If no parameter is given, proxy will be toggled
END
      ;;
  esac
}

# Try to login to a remote machine indefinitely
ssh_wait () {
  local MY_USER MY_HOST INPUT
  [[ -z "$1" || $# -ne 1 ]] && return 1
  INPUT=$1
  if [[ "$INPUT" =~ @ ]]; then
    MY_USER=${INPUT%@*}
    MY_HOST=${INPUT#*@}
  else
    MY_HOST=$INPUT
  fi
  MY_USER=${MY_USER:-${USER,,}}

  while true; do
    if (echo >"/dev/tcp/${MY_HOST}/22") &>/dev/null; then
      ssh -q -o "BatchMode yes" -l "$MY_USER" "$MY_HOST" && break
    fi
    sleep 5
  done
}

rdp () {
  [[ -z "$1" ]] && return 1
#  /usr/local/bin/xfreerdp +clipboard /kbd:0x00000407 /d:global /u:"${USER,,}" /cert-tofu /w:1840 /h:1030 /bpp:32 /audio-mode:1 /v:"$1"
  /usr/local/bin/xfreerdp +clipboard /kbd:0x00000407 /d:global /u:"${USER,,}" /cert-tofu /size:1920x1080 /smart-sizing:2880x1620 /bpp:32 /audio-mode:1 /v:"$1"
}

# Print Git branch if available
__git_branch() {
  local BRANCH
  BRANCH=$(git symbolic-ref -q --short HEAD 2>/dev/null) || return
  [[ -z "$BRANCH" ]] && return
  echo " (${BRANCH})"
}

## Aliases
alias ls="\ls $COLOR_OPT"
alias lt="\ls -lat $COLOR_OPT"
alias ll="\ls -l $COLOR_OPT"
alias la="\ls -la $COLOR_OPT"
alias lah="\ls -lAh $COLOR_OPT"
alias dir="\ls -lA $COLOR_OPT"
alias rm="\rm -i"
alias cp="\cp -i"
alias mv="\mv -iv"
alias df="\df -h"
alias du="\du -h"
alias nslookup="\nslookup -sil"
alias digs="\dig +noall +answer"
alias scr="\screen -dR"
alias grep="\grep $COLOR_OPT"
alias egrep="\egrep $COLOR_OPT"
alias ssh_all='ssh -A -t lw2017 ssh -A'
alias ssh_rdp='ssh -t -L 9999:localhost:4444 jump ssh -N -L 4444:localhost:3389'
if [[ -d ~/git_cc/bs-automation/tools-templates/settings ]]; then
  alias foodcritic='foodcritic -r ~/git_cc/bs-automation/tools-templates/settings/.foodcritic'
  alias rubo='rubocop --config ~/git_cc/bs-automation/tools-templates/settings/.rubocop.yml'
fi

if which vim &>/dev/null; then
  export EDITOR=vim
  alias vi="\vim"
  alias view="\vim -R"
fi
alias cf2go="cf2go -u ${USER,,}"

case "$TERM" in
xterm*|rxvt*|screen*)
  export PS1='\[\e['${PROMPT_COLOR}'\]\u@\h:\w$([ \j -gt 0 ] && echo [\j])$(__git_branch)\$\[\e[m\]'
  ;;
linux*)
  export PS1='\[\e['${PROMPT_COLOR}'\]\u@\h:\w$([ \j -gt 0 ] && echo [\j])$(__git_branch)\$\[\e[m\]'
  unset PROMPT_COMMAND
  ;;
*)
  export PS1='\[\u@\h:\w$([ \j -gt 0 ] && echo [\j])\$i\]$(__git_branch)'
  ;;
esac

# EOF
