if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=100000000
export SAVEHIST=100000000
export FPATH=$HOME/dotfiles/zsh_autocomplete_rclone:$FPATH
export PATH=$PATH:$HOME/.local/bin:$HOME/.local/share/gem/ruby/3.0.0/bin
export VISUAL=nano
export EDITOR="$VISUAL"
export ZSH_DISABLE_COMPFIX=true
export QT_QPA_PLATFORM=xcb # Fix for some QT applications in Wayland
# The following export looks bad and should be a workaround, this should be fixed in a fresh install
export npm_config_prefix="$HOME/.local"
export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock # Docker rootless

alias lschmod='ls -la | awk '\''{k=0;for(i=0;i<=8;i++)k+=((substr($1,i+2,1)~/[rwx]/)*2^(8-i));if(k)printf("%0o ",k);print}'\'
alias l1="ls -1"
alias rm='nocorrect rm'

## Choose theme based on emulator
function choosetheme()
{
	if [[ "${DISPLAY}" ]]; then
		# Using a display compositor
		source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
	else
	# We're in TTY
		prompt giddie # Brutal, I know, but for the life of me I couldn't get it to work in any other way
	fi
}
## End of choose theme

bindkey '^[[3;5~' kill-word
bindkey '^H' backward-kill-word

choosetheme

############### POWERLEVEL 10K ################
POWERLEVEL9K_MODE='nerdfont-complete'

POWERLEVEL9K_BATTERY_VERBOSE=false
POWERLEVEL9K_BATTERY_CHARGING='yellow'
POWERLEVEL9K_BATTERY_CHARGED='green'
POWERLEVEL9K_BATTERY_DISCONNECTED='$DEFAULT_COLOR'
POWERLEVEL9K_BATTERY_LOW_THRESHOLD='25'
POWERLEVEL9K_BATTERY_LOW_COLOR='red'
POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=''
POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX='\uf0da'

POWERLEVEL9K_VCS_MODIFIED_BACKGROUND='yellow'
POWERLEVEL9K_VCS_UNTRACKED_BACKGROUND='yellow'

POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(status battery user dir vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(time virtualenv rbenv rvm)

POWERLEVEL9K_SHORTEN_STRATEGY="truncate_middle"
POWERLEVEL9K_SHORTEN_DIR_LENGTH=4

POWERLEVEL9K_TIME_FORMAT="%D{%H:%M}"

POWERLEVEL9K_PROMPT_ON_NEWLINE=true
############# END POWERLEVEL 10K ##############

PATH="/home/federico/perl5/bin${PATH:+:${PATH}}"; export PATH;
PERL5LIB="/home/federico/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"; export PERL5LIB;
PERL_LOCAL_LIB_ROOT="/home/federico/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"; export PERL_LOCAL_LIB_ROOT;
PERL_MB_OPT="--install_base \"/home/federico/perl5\""; export PERL_MB_OPT;
PERL_MM_OPT="INSTALL_BASE=/home/federico/perl5"; export PERL_MM_OPT;

source $HOME/.zpreztorc
source /usr/lib/prezto/init.zsh
