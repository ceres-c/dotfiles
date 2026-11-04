#!/bin/bash
# Stop on a failed package install or setup operation.
set -e
#
# Install this dotfile setup on a Debian GNOME VM in Parallels.
#

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
cd "$DOTFILES" || exit 1

# Install Sauce Code Pro Nerd Font into the user's font directory.
install_nerdfont() {
	if fc-list 2>/dev/null | grep -qi 'SauceCodePro Nerd Font'; then
		return
	fi
	local version="${NERD_FONTS_VERSION:-v3.5.1}"
	local tmp
	tmp="$(mktemp -d)"
	echo "[#] Installing SauceCodePro Nerd Font ${version}"
	if curl -fL --retry 3 \
		-o "$tmp/SourceCodePro.zip" \
		"https://github.com/ryanoasis/nerd-fonts/releases/download/${version}/SourceCodePro.zip"; then
		mkdir -p "$HOME/.local/share/fonts/SauceCodeProNerdFont"
		unzip -oq "$tmp/SourceCodePro.zip" -d "$HOME/.local/share/fonts/SauceCodeProNerdFont"
		fc-cache -f "$HOME/.local/share/fonts" >/dev/null
	fi
	rm -rf "$tmp"
}

# Terminator rewrites its config every time it exits, so symlinking it would
# let the GUI overwrite the repo. Copy it instead; re-run copier.sh to reset it.
install_terminator_config() {
	mkdir -p "$HOME/.config/terminator"
	cp "$DOTFILES/terminator.conf" "$HOME/.config/terminator/config"
}

install_gnome_extensions() {
	local ding_package="gnome-shell-extension-desktop-icons-ng"
	local dock_package="gnome-shell-extension-dashtodock"
	local -a extension_ids=("ding@rastersoft.com" "dash-to-dock@micxgx.gmail.com")
	local missing_packages=()
	local package

	for package in "$ding_package" "$dock_package"; do
		if ! dpkg-query -W -f='${db:Status-Status}' "$package" 2>/dev/null | grep -qx 'installed'; then
			missing_packages+=("$package")
		fi
	done

	if (( ${#missing_packages[@]} )); then
		sudo apt-get update
		sudo apt-get install -y "${missing_packages[@]}"
	fi

	# A freshly installed extension is unknown to the RUNNING GNOME Shell (it
	# only scans extension directories at startup), so "gnome-extensions enable"
	# would fail with 'does not exist'. Write the enablement through gsettings
	# instead: it persists and applies at the next login.
	python3 - "${extension_ids[@]}" <<'PY'
import ast
import subprocess
import sys

raw = subprocess.check_output(
    ["gsettings", "get", "org.gnome.shell", "enabled-extensions"], text=True
).strip()
enabled = ast.literal_eval(raw.replace("@as ", ""))
missing = [extension for extension in sys.argv[1:] if extension not in enabled]
if missing:
    enabled.extend(missing)
    value = "[" + ", ".join(repr(extension) for extension in enabled) + "]"
    subprocess.run(
        ["gsettings", "set", "org.gnome.shell", "enabled-extensions", value],
        check=True,
    )
    print("[#] Enabled " + ", ".join(missing) + " (active after next login)")
PY

	# Best-effort live activation, for re-runs where the shell already knows
	# the extensions. Must not abort the script on a fresh VM.
	local id
	for id in "${extension_ids[@]}"; do
		gnome-extensions enable "$id" 2>/dev/null || true
	done
	echo "Dash to Dock is configured to stay visible."
	if [[ "${XDG_SESSION_TYPE:-}" == wayland ]]; then
		echo "Log out and back in once so GNOME loads freshly installed extensions."
	fi
}

# This branch intentionally targets Debian GNOME VMs only.
# shellcheck disable=SC1091
. /etc/os-release
if [[ "${ID:-}" != debian ]]; then
	echo "[!] This setup supports Debian GNOME VMs; found ${ID:-unknown}." >&2
	exit 1
fi
if [[ "${XDG_CURRENT_DESKTOP:-}" != *GNOME* ]]; then
	echo "[!] Run this setup from a GNOME desktop session." >&2
	exit 1
fi

# ---------------------------------------------------------------- packages ---
sudo apt-get update
sudo apt-get install -y \
	zsh tmux nano htop git curl unzip fontconfig \
	terminator gnome-tweaks keyd keyd-application-mapper

install_gnome_extensions

# Prezto + Powerlevel10k (Debian does not package Prezto).
if [ ! -d "$HOME/.zprezto" ]; then
	git clone --recursive https://github.com/sorin-ionescu/prezto.git "$HOME/.zprezto"
fi
if [ ! -d "$HOME/.powerlevel10k" ]; then
	git clone --depth 1 https://github.com/romkatv/powerlevel10k.git "$HOME/.powerlevel10k"
fi

install_nerdfont
git submodule update --init --recursive

# ---------------------------------------------------------- system config ---
# Nano syntax highlighting. Debian ships a subset; the repo supplies the rest.
for i in nano/*.nanorc; do
	[ -e "$i" ] && sudo ln -rsf "$i" "/usr/share/nano/$(basename "$i")"
done

# Development tools commonly need more file watches (e.g. VS Code).
sudo ln -rsf 40-max-user-watches.conf /etc/sysctl.d/40-max-user-watches.conf

# Parallels keyboard remaps: Option arrows move by word; Command arrows move
# to line boundaries; Command+Backspace/Delete synthesize line-selection keys.
sudo mkdir -p /etc/keyd
sudo ln -rsf "$DOTFILES/keyd-parallels.conf" /etc/keyd/option-word-nav.conf
sudo systemctl enable --now keyd
if command -v keyd.rvaiya >/dev/null 2>&1; then
	sudo keyd.rvaiya reload
elif command -v keyd >/dev/null 2>&1; then
	sudo keyd reload
fi

# Per-application remaps (see keyd-app.conf): VTE swallows Shift+Home/End, so
# Terminator gets Command+Backspace/Delete as Ctrl+U/Ctrl+K instead.
install_keyd_app_mapper() {
	mkdir -p "$HOME/.config/keyd"
	cp "$DOTFILES/keyd-app.conf" "$HOME/.config/keyd/app.conf"

	# Access to keyd's control socket; takes effect on the next login.
	sudo gpasswd -a "$(id -un)" keyd >/dev/null 2>&1 || true

	# GNOME extension that reports the focused window to the mapper. The
	# packaged metadata lags behind GNOME; widen it and enable the extension
	# for the next session (the running shell only scans extensions at
	# startup).
	local ext_src="/usr/share/keyd/gnome-extension-45"
	[ -d "$ext_src" ] || ext_src="/usr/share/keyd/gnome-extension"
	local ext_dir="$HOME/.local/share/gnome-shell/extensions/keyd"
	mkdir -p "$ext_dir"
	cp "$ext_src/extension.js" "$ext_src/metadata.json" "$ext_dir/"
	python3 - "$ext_dir/metadata.json" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
meta = json.loads(path.read_text())
meta["shell-version"] = sorted(set(meta["shell-version"]) | {"47", "48"})
path.write_text(json.dumps(meta, indent=1) + "\n")
PY
	python3 - <<'PY'
import ast
import subprocess

raw = subprocess.check_output(
    ["gsettings", "get", "org.gnome.shell", "enabled-extensions"], text=True
).strip()
extensions = ast.literal_eval(raw.replace("@as ", ""))
if "keyd" not in extensions:
    extensions.append("keyd")
    value = "[" + ", ".join(repr(e) for e in extensions) + "]"
    subprocess.run(
        ["gsettings", "set", "org.gnome.shell", "enabled-extensions", value],
        check=True,
    )
PY
}
install_keyd_app_mapper

# ------------------------------------------------------------ user config ---
ln -rsf .tmux.conf "$HOME/.tmux.conf"
ln -rsfT .tmux "$HOME/.tmux"
ln -rsf .zshrc "$HOME/.zshrc"
ln -rsf .zpreztorc "$HOME/.zpreztorc"
ln -rsf .gitconfig "$HOME/.gitconfig"
ln -rsf .pam_environment "$HOME/.pam_environment"

mkdir -p "$HOME/.config/nano"
ln -rsf nanorc "$HOME/.config/nano/nanorc"
ln -rsf nanorc "$HOME/.nanorc" # nano < 7 only reads this path

install_terminator_config

# GNOME/systemd user environment.
if [ -d "$DOTFILES/environment.d" ]; then
	mkdir -p "$HOME/.config/environment.d"
	ln -rsf environment.d/90-desktop.conf "$HOME/.config/environment.d/90-desktop.conf"
fi

# Start ssh-agent on login (Debian uses socket activation)
if [ -n "${XDG_RUNTIME_DIR:-}" ]; then
	systemctl --user enable --now ssh-agent.socket 2>/dev/null || true
fi
sudo ln -rsf ssh_auth_sock.sh /etc/profile.d/ssh_auth_sock.sh

# OpenCode CLI input bindings. Merge these into the global CLI settings so
# themes and other user preferences are preserved.
OPENCODE_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
mkdir -p "$OPENCODE_CONFIG_DIR"
python3 - "$DOTFILES/opencode-cli.json" "$OPENCODE_CONFIG_DIR/cli.json" <<'PY'
import json
import pathlib
import sys

source_path, target_path = map(pathlib.Path, sys.argv[1:])
source = json.loads(source_path.read_text())
target = json.loads(target_path.read_text()) if target_path.exists() else {}

for key, value in source.items():
    if key == "$schema":
        target.setdefault(key, value)
    elif isinstance(value, dict):
        current = target.setdefault(key, {})
        if not isinstance(current, dict):
            raise TypeError(f"{key} must be an object in {target_path}")
        current.update(value)
    else:
        target[key] = value

target_path.write_text(json.dumps(target, indent=2) + "\n")
PY

# GNOME desktop preferences: default terminal, fonts, dark theme, touchpad,
# Ctrl+Alt+T and Terminator in the dash.
"$DOTFILES/gnome-settings.sh"

# Use zsh as the login shell.
if command -v zsh >/dev/null 2>&1 && [ "${SHELL:-}" != "$(command -v zsh)" ]; then
	echo "[!] Run 'chsh -s $(command -v zsh)' to make zsh your login shell"
fi
