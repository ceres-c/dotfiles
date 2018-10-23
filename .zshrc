export ZSH=/home/federico/.oh-my-zsh
export FPATH=$HOME/dotfiles/zsh_autocomplete_rclone:$FPATH
export PATH=$PATH:/home/federico/.local/bin
export VISUAL=nano
export EDITOR="$VISUAL"
# The following export looks bad and should be a workaround, this should be fixed in a fresh install
export PYTHONPATH="/usr/lib/python3.7/site-packages/"

alias restartusb='echo 0000:00:14.0 | sudo tee /sys/bus/pci/drivers/xhci_hcd/unbind; sleep 5; echo 0000:00:14.0 | sudo tee /sys/bus/pci/drivers/xhci_hcd/bind'
alias lschmod='ls -la | awk '\''{k=0;for(i=0;i<=8;i++)k+=((substr($1,i+2,1)~/[rwx]/)*2^(8-i));if(k)printf("%0o ",k);print}'\'
alias l1="ls -1"
alias sugo=sudo

bindkey '\e[3;3~' kill-word

plugins=(git history-substring-search)
source $ZSH/oh-my-zsh.sh

## Choose theme based on emulator
function choosetheme()
{
	if [ -n "${COLORTERM}" ]
# Working in a colorful terminal
	then
		source /usr/share/zsh-theme-powerlevel9k/powerlevel9k.zsh-theme
	else
# Is this TTY?
		ZSH_THEME=pygmalion
	fi
}

choosetheme

################ POWERLEVEL 9K ################
POWERLEVEL9K_MODE='nerdfont-complete'

POWERLEVEL9K_BATTERY_CHARGING='yellow'
POWERLEVEL9K_BATTERY_CHARGED='green'
POWERLEVEL9K_BATTERY_DISCONNECTED='$DEFAULT_COLOR'
POWERLEVEL9K_BATTERY_LOW_THRESHOLD='15'
POWERLEVEL9K_BATTERY_LOW_COLOR='red'
POWERLEVEL9K_BATTERY_ICON='\uf1e6'
POWERLEVEL9K_HOME_ICON='\uE12C'
POWERLEVEL9K_VCS_GIT_GITHUB_ICON='\uF408'
POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=''
POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX='\uf0da'

POWERLEVEL9K_VCS_MODIFIED_BACKGROUND='yellow'
POWERLEVEL9K_VCS_UNTRACKED_BACKGROUND='yellow'

POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(status battery user dir vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(time background_jobs ram virtualenv rbenv rvm)

POWERLEVEL9K_SHORTEN_STRATEGY="truncate_middle"
POWERLEVEL9K_SHORTEN_DIR_LENGTH=4

POWERLEVEL9K_TIME_FORMAT="%D{\uf017 %H:%M}"

POWERLEVEL9K_STATUS_VERBOSE=true

POWERLEVEL9K_PROMPT_ON_NEWLINE=true
############## END POWERLEVEL 9K ##############
