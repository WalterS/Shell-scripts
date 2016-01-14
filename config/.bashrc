############################################################
# .bashrc
#
############################################################

# Source global definitions
if [[ -f /etc/bashrc ]]; then
	. /etc/bashrc
fi

# Disable timeout
if [[ -n "$TMOUT" ]]; then
	env -i bash --init-file $0
fi

# Add local bin to path if present
if [[ -d "$HOME/bin" ]] ; then
	if [[ ! ":${PATH}:" == *":${HOME}/bin:"* ]]; then
		PATH="$HOME/bin:$PATH"
	fi
fi
for p in /sbin /usr/sbin; do
	if [[ ! ":${PATH}:" == *":${p}:"* ]]; then
		PATH=${PATH}:$p
	fi
done
unset p

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
export PAGER=less

# Set history format to "%n %y-%m-%d %T %command":
# export HISTTIMEFORMAT="%y-%m-%d %T "

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
	if [[ "$UID" = 0 ]]; then
		PROMPT_COLOR="1;31m"
	fi
fi

## Functions

# Show if we are in a screen session
is_screen (){
[[ -n "$STY" ]] && echo "This is a screen session"
}

# Function for process list search
# Search process list for a given string (case insensitiv)
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
STR=$(sed 's/\//\\\\\//g; s/\!/\\\!/g; s/\?/\\\?/g'<<<$STR)

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
local GITHUB='github.com'
local REPONAME=${PWD##*/}
local REPOBRANCH
if ! egrep -qw 'master|release'<<<$1; then
	REPOBRANCH='master'
else
	REPOBRANCH=$1
fi
if ! 'grep' -q 'remote "'$REPONAME'"' ~/.gitconfig; then
	echo "$REPONAME is not defined in ~/.gitconfig, trying Github"
	REPONAME="$(sed 's#^.*git/#git@'$GITHUB':#'<<<$(pwd)).git"
fi

git checkout $REPOBRANCH &> /dev/null
git pull --rebase $REPONAME $REPOBRANCH
}

# Try to login to a remote machine indefinitely
ssh_wait () {
local MY_USER MY_HOST INPUT
[[ -z "$1" || $# -ne 1 ]] && return 1
INPUT=$1
if [[ "$INPUT" =~ @ ]]; then
	MY_USER="${INPUT%@*}@"
	MY_HOST=${INPUT#*@}
else
	MY_HOST=$INPUT
fi

while true; do
	if (echo >/dev/tcp/${MY_HOST}/22) &>/dev/null; then
		ssh ${MY_USER}${MY_HOST}
		break
	fi
	sleep 5
done
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
if which vim &>/dev/null; then
	export EDITOR=vim
	alias vi="\vim"
	alias view="\vim -R"
fi

case "$TERM" in
xterm*|rxvt*|screen*)
	export PS1='\[\e['${PROMPT_COLOR}'\]\u@\h:\w[\!]\$\[\e[m\]'
	;;
linux*)
	export PS1='\[\e['${PROMPT_COLOR}'\]\u@\h:\w[\!]\$\[\e[m\]'
	unset PROMPT_COMMAND
	;;
*)
	export PS1='\[\u@\h:\w[\!]\$i\]'
	;;
esac

# EOF
