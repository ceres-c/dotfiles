#!/bin/bash
# Apply GNOME preferences for the Debian Parallels VM.
# Safe to run repeatedly; every change is idempotent.

set -e

if ! command -v gsettings >/dev/null 2>&1; then
	echo "[!] gsettings not found, skipping GNOME configuration"
	exit 0
fi

# ---------------------------------------------------------------- terminal --
# Make Terminator the default terminal for GNOME and for XDG-aware apps.
gsettings set org.gnome.desktop.default-applications.terminal exec 'terminator'
gsettings set org.gnome.desktop.default-applications.terminal exec-arg '-x'
mkdir -p "$HOME/.config"
printf 'terminator.desktop\n' > "$HOME/.config/xdg-terminals.list"
# GNOME-specific override used by some components instead of the XDG list.
printf 'terminator.desktop\n' > "$HOME/.config/gnome-xdg-terminals.list"

if command -v update-alternatives >/dev/null 2>&1 && \
   update-alternatives --query x-terminal-emulator >/dev/null 2>&1; then
	sudo update-alternatives --set x-terminal-emulator /usr/bin/terminator 2>/dev/null || true
fi

# Ctrl+Alt+T opens Terminator. Register it through the custom-keybindings list
# without clobbering shortcuts that are already defined.
TERMINATOR_KEY_PATH='/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/terminator/'
TERMINATOR_KEY_SCHEMA="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${TERMINATOR_KEY_PATH}"
gsettings set "$TERMINATOR_KEY_SCHEMA" name 'Terminator'
gsettings set "$TERMINATOR_KEY_SCHEMA" command 'terminator'
gsettings set "$TERMINATOR_KEY_SCHEMA" binding '<Control><Alt>t'
python3 - "$TERMINATOR_KEY_PATH" <<'PY'
import ast
import subprocess
import sys

path = sys.argv[1]
schema = 'org.gnome.settings-daemon.plugins.media-keys'
raw = subprocess.check_output(['gsettings', 'get', schema, 'custom-keybindings'], text=True).strip()
if raw in ('@as []', '[]'):
    paths = []
else:
    paths = list(ast.literal_eval(raw.replace('@as ', '')))
if path not in paths:
    paths.append(path)
    value = '[' + ', '.join(repr(p) for p in paths) + ']'
    subprocess.run(['gsettings', 'set', schema, 'custom-keybindings', value], check=True)
PY

# Terminator uses Super+1..9 to select tabs. Release these shortcuts from
# GNOME's dock application switcher so Terminator receives them.
for n in 1 2 3 4 5 6 7 8 9; do
	gsettings set org.gnome.shell.keybindings "switch-to-application-$n" '[]'
done

# Keep Dash to Dock visible instead of autohiding or intellihiding it.
DOCK_SCHEMA='org.gnome.shell.extensions.dash-to-dock'
gsettings set "$DOCK_SCHEMA" dock-fixed true
gsettings set "$DOCK_SCHEMA" autohide false
gsettings set "$DOCK_SCHEMA" intellihide false
gsettings set "$DOCK_SCHEMA" manualhide false
# Dash to Dock has its own app launch shortcuts, separate from GNOME Shell's.
for n in 1 2 3 4 5 6 7 8 9 10; do
	gsettings set "$DOCK_SCHEMA" "app-hotkey-$n" '[]'
done
echo "Dash to Dock is configured to stay visible."

# Pin Terminator to the dash, preserving the existing favourites.
python3 - <<'PY'
import ast
import subprocess

schema = 'org.gnome.shell'
key = 'favorite-apps'
raw = subprocess.check_output(['gsettings', 'get', schema, key], text=True).strip()
favourites = list(ast.literal_eval(raw.replace('@as ', '')))
if 'terminator.desktop' not in favourites:
    favourites.append('terminator.desktop')
    value = '[' + ', '.join(repr(a) for a in favourites) + ']'
    subprocess.run(['gsettings', 'set', schema, key, value], check=True)
PY

# ---------------------------------------------------------------- fonts ------
# Monospace font used in Terminator.
gsettings set org.gnome.desktop.interface monospace-font-name 'SauceCodePro Nerd Font 15'

# ---------------------------------------------------------------- theme ------
# Breeze Dark was the old desktop theme; use the closest stock GNOME equivalent.
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

# Keep window controls on the right.
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'

# ---------------------------------------------------------------- input ------
# Tap-to-click and traditional (non-natural) scrolling for the VM touchpad.
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll false

# macOS KeyRepeat/InitialKeyRepeat equivalents: fast repeat, short delay.
gsettings set org.gnome.desktop.peripherals.keyboard delay 250
gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 30

# ---------------------------------------------------------------- nautilus ---
# Finder's AppleShowAllFiles equivalent.
gsettings set org.gnome.nautilus.preferences show-hidden-files true

echo "[#] GNOME settings applied"
