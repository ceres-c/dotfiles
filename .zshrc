############### POWERLEVEL10K INSTANT PROMPT ################
# MUST stay at the very top of this file. Anything that produces output or
# reads from stdin above this point breaks the instant prompt.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

############### ENVIRONMENT ################
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=100000000
export SAVEHIST=100000000
DOTFILES="${DOTFILES:-$HOME/dotfiles}"
if [[ -d "$DOTFILES/zsh_autocomplete_rclone" ]]; then
  export FPATH="$DOTFILES/zsh_autocomplete_rclone:$FPATH"
fi
export PATH="$PATH:$HOME/.local/bin:$HOME/.local/share/gem/ruby/3.0.0/bin"
export PATH="$HOME/.opencode/bin:$PATH"
export VISUAL=nano
export EDITOR="$VISUAL"
export ZSH_DISABLE_COMPFIX=true
# Qt applications use Wayland natively, with X11 fallback when needed.
# The following export looks bad and should be a workaround, this should be fixed in a fresh install
export npm_config_prefix="$HOME/.local"
export DOCKER_HOST="unix://${XDG_RUNTIME_DIR:-/run/user/$UID}/docker.sock" # Docker rootless

############### PREZTO ################
# Sourced BEFORE powerlevel10k so prezto can never override the prompt.
# NOTE: init.zsh sources ~/.zpreztorc itself -- do not source it manually.
if [[ -r "$HOME/.zprezto/init.zsh" ]]; then
  source "$HOME/.zprezto/init.zsh"
elif [[ -r /usr/lib/prezto/init.zsh ]]; then
  source /usr/lib/prezto/init.zsh
fi

############### POWERLEVEL 10K ################
# All POWERLEVEL9K_* settings must be assigned BEFORE the theme is sourced.
# p10k snapshots its configuration at load time; later assignments are silently
# ignored unless followed by an explicit `p10k reload`.

# There is no ~/.p10k.zsh on this machine, so configure inline and suppress the
# interactive wizard. Without this, p10k blocks the shell waiting for keypresses.
typeset -g POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true

# Make p10k emit the OSC 133/633 marks itself, otherwise it wipes the markers
# VS Code injects when it redraws PROMPT.
typeset -g POWERLEVEL9K_TERM_SHELL_INTEGRATION=true

typeset -g POWERLEVEL9K_MODE='nerdfont-complete'

typeset -g POWERLEVEL9K_BATTERY_VERBOSE=false
typeset -g POWERLEVEL9K_BATTERY_CHARGING='yellow'
typeset -g POWERLEVEL9K_BATTERY_CHARGED='green'
typeset -g POWERLEVEL9K_BATTERY_DISCONNECTED="$DEFAULT_COLOR"
typeset -g POWERLEVEL9K_BATTERY_LOW_THRESHOLD='25'
typeset -g POWERLEVEL9K_BATTERY_LOW_COLOR='red'
typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=''
# $'...' so the escape actually becomes the glyph rather than a literal \uf0da
typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX=$'\uf0da'

typeset -g POWERLEVEL9K_VCS_MODIFIED_BACKGROUND='yellow'
typeset -g POWERLEVEL9K_VCS_UNTRACKED_BACKGROUND='yellow'

typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(status user dir vcs)
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(time virtualenv)

typeset -g POWERLEVEL9K_SHORTEN_STRATEGY="truncate_middle"
typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=4

typeset -g POWERLEVEL9K_TIME_FORMAT="%D{%H:%M}"

typeset -g POWERLEVEL9K_PROMPT_ON_NEWLINE=true

# In a graphical session use p10k; on a bare TTY fall back to a Prezto prompt.
if [[ -n "$DISPLAY" || -n "$WAYLAND_DISPLAY" ]]; then
  for _p10k_theme in \
    "$HOME/.powerlevel10k/powerlevel10k.zsh-theme" \
    /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme \
    /usr/share/powerlevel10k/powerlevel10k.zsh-theme; do
    if [[ -r "$_p10k_theme" ]]; then
      source "$_p10k_theme"
      break
    fi
  done
  unset _p10k_theme
  # If a generated config ever appears (via `p10k configure`), let it win.
  [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
else
  # The prompt pmodule is deliberately not loaded by ~/.zpreztorc (it would
  # fight p10k); load it on demand for bare TTY sessions only.
  if (( ! $+functions[prompt] && $+functions[pmodload] )); then
    pmodload prompt
  fi
  if (( $+functions[prompt] )); then
    prompt giddie # Brutal, I know, but for the life of me I couldn't get it to work in any other way
  fi
fi
############# END POWERLEVEL 10K ##############

############### ALIASES ################
alias lschmod='ls -la | awk '\''{k=0;for(i=0;i<=8;i++)k+=((substr($1,i+2,1)~/[rwx]/)*2^(8-i));if(k)printf("%0o ",k);print}'\'
alias l1="ls -1"
alias rm='nocorrect rm'

############### KEYBINDINGS ################
# After prezto's `editor` module, otherwise these get clobbered.
#
# keyd translates the macOS modifiers system-wide, so ZLE receives:
#   Option+Left/Right    -> Ctrl+Left/Right     (zsh binds these by default)
#   Option+Backspace     -> Ctrl+Backspace (^H) (zsh's default deletes one char)
#   Option+Fn+Backspace  -> Ctrl+Delete
#   Cmd+Backspace        -> Home Home Shift+End Backspace
#   Cmd+Fn+Backspace     -> Shift+End Delete
# ZLE has no selection, so the synthesized Shift+End becomes a forward kill and
# Shift+Home a whole-line kill. VTE 0.80 encodes these as CSI 1;2 H/F. Bind in
# both common keymaps; keep Meta fallbacks for ssh sessions without keyd.

# Word movement and word delete via Meta keys (no keyd, e.g. ssh).
bindkey $'\e[1;3D' backward-word
bindkey $'\e[1;3C' forward-word
bindkey $'\e\e[D' backward-word
bindkey $'\e\e[C' forward-word
bindkey $'\eb' backward-word
bindkey $'\ef' forward-word
bindkey $'\e\177' backward-kill-word
bindkey $'\e[127;3u' backward-kill-word

for _map in emacs viins; do
  # keyd's Option translations.
  bindkey -M "$_map" '^H' backward-kill-word
  bindkey -M "$_map" $'\e[127;5u' backward-kill-word
  bindkey -M "$_map" $'\e[3;5~' kill-word
  # keyd's Cmd+Backspace / Cmd+Fn+Backspace synthesized sequences.
  bindkey -M "$_map" $'\e[1;2H' kill-whole-line
  bindkey -M "$_map" $'\e[1;2F' kill-line
  bindkey -M "$_map" $'\e[4;2~' kill-line
done
unset _map

############### PERL LOCAL LIB ################
if [[ -d "$HOME/perl5" ]]; then
  PATH="$HOME/perl5/bin${PATH:+:${PATH}}"; export PATH
  PERL5LIB="$HOME/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"; export PERL5LIB
  PERL_LOCAL_LIB_ROOT="$HOME/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"; export PERL_LOCAL_LIB_ROOT
  PERL_MB_OPT="--install_base \"$HOME/perl5\""; export PERL_MB_OPT
  PERL_MM_OPT="INSTALL_BASE=$HOME/perl5"; export PERL_MM_OPT
fi

############### VS CODE SHELL INTEGRATION ################
# p10k unsets VSCODE_SHELL_INTEGRATION during init, so source the integration
# at the end with both VSCODE_SHELL_INTEGRATION and VSCODE_INJECTION unset.
if [[ "$TERM_PROGRAM" == "vscode" ]]; then
  _vsc_si_path=""
  if [[ -n "$VSCODE_ZDOTDIR" && -r "$VSCODE_ZDOTDIR/.zshrc" ]]; then
    _vsc_si_path="$VSCODE_ZDOTDIR/.zshrc"
  else
    _vsc_si_path="$(code --locate-shell-integration-path zsh 2>/dev/null)"
  fi
  if [[ -n "$_vsc_si_path" && -r "$_vsc_si_path" ]]; then
    # Both variables must be UNSET here: setting VSCODE_SHELL_INTEGRATION
    # disables the script's own entry point, and VSCODE_INJECTION=1 makes it
    # re-source this file recursively.
    : ${USER_ZDOTDIR:=$HOME}
    unset VSCODE_SHELL_INTEGRATION VSCODE_INJECTION
    source "$_vsc_si_path"

    # Drop the one spurious OSC 633;D emitted during startup (it otherwise
    # makes the first command of a fresh shell look instantly finished).
    __vsc_drop_startup_d() {
      if (( $+functions[__vsc_command_complete] )); then
        functions[__vsc_command_complete_orig]=$functions[__vsc_command_complete]
        __vsc_command_complete() {
          functions[__vsc_command_complete]=$functions[__vsc_command_complete_orig]
          __vsc_update_cwd
        }
      fi
      precmd_functions=(${precmd_functions:#__vsc_drop_startup_d})
      unfunction __vsc_drop_startup_d
    }
    precmd_functions=(__vsc_drop_startup_d $precmd_functions)
  fi
  unset _vsc_si_path
fi
