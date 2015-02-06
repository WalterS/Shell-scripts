############################################################
# .bashrc
#
############################################################

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

## Setting up the environment
# Add sbin and user's bin to system path
PATH="~/bin:/sbin:/usr/sbin:${PATH}"
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

# Remove duplicates from path
path_condense () {
	PATH=$(sed 's#~#'$(echo ~)'#g'<<<$PATH)
	export PATH=$(awk -F: '{for(i=1;i<=NF;i++) if(!($i in arr)){arr[$i];printf s$i;s=":"}} END {print ""}'<<<$PATH)
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
	local STR=$(sed 's/\//\\\\\//g; s/\!/\\\!/g; s/\?/\\\?/g'<<<$STR)

	# If no search expression given, just print the whole history
	if [[ -z "$STR" ]]; then
		history
		return
	fi

	local LHISTCMD=$((HISTCMD-1))
	history | awk -F'^ *[0-9]+ +' 'BEGIN {IGNORECASE=1}; $2~/'"$STR"'/' |  awk '$1 !~ /'"$LHISTCMD"'/'
	# If 'HISTTIMEFORMAT="%y-%m-%d %T "' is used:
	# history | awk -F'^.*[0-9][0-9]:[0-9][0-9]:[0-9][0-9] +' 'BEGIN {IGNORECASE=1}; $2~/'"$STR"'/' |  awk '$1 !~ /'"$LHISTCMD"'/'
}

# Function for pulling Git repository
git_current() {
	local LPWD
	LPWD=${PWD##*/}
	if ! grep -q 'remote "'$LPWD'"' ~/.gitconfig; then
		echo "$LPWD is not defined in ~/.gitconfig" >&2
		return 1
	fi
	git pull $LPWD --rebase
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

path_condense

# EOF
