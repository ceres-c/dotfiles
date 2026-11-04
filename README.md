# Debian GNOME Parallels dotfiles

This branch is for the Debian GNOME guest in Parallels. It is not a cross-distro
or macOS-host installer.

Run `./copier.sh` from the cloned repository. It installs the shell and terminal
tools, Prezto/Powerlevel10k, Terminator, the Parallels keyboard remaps, Desktop
Icons NG, and Dash to Dock, keeps the display scale fixed across monitor
switches, then applies the GNOME preferences.

## Keyboard shortcuts

- Option+Left/Right moves by word in text fields and terminals.
- Option+Backspace/Delete deletes the previous/next word (sent to apps as
  Ctrl+Backspace/Delete). Inside Terminator they are delivered as Ctrl+W and
  Ctrl+Delete instead, because OpenCode's TUI decodes the Ctrl+Backspace byte
  as a plain backspace.
- Command+Left/Right moves to the start/end of a line.
- Command+Backspace/Delete selects and deletes to the line boundary in text
  fields; inside Terminator (and the OpenCode TUI) they are delivered as
  Ctrl+U/Ctrl+K instead, because VTE intercepts Shift+Home/Shift+End for
  scroll-to-top/bottom. Requires logging out and back in once so the keyd
  GNOME extension and the `keyd` group take effect.
- In Terminator, Command+1–9 selects tabs 1–9; Command+0 selects tab 10.
- Command+Option+Left/Right moves focus between Terminator panes.
- OpenCode's TUI uses Command+Left/Right for input-line boundaries rather than
  transcript navigation.
- VS Code's integrated terminal gets canonical Home/End sequences via
  vscode-keybindings.json (installed by copier.sh), so the same Cmd shortcuts
  work there without relying on xterm.js's key encoding.

GNOME Shell and Dash to Dock's Super+1–9/0 app-launch shortcuts are disabled so
Terminator can use those combinations for tabs. Terminator's default “insert
terminal number” bindings on Super+1 and Super+0 are disabled as well.

## Display scaling

The VM presents a single virtual display whose resolution mode changes whenever
the VM window moves between host displays; mutter's fallback then resets the UI
scale to 100%. The `fixed-display-scale` user service (installed by `copier.sh`
from `fixed-display-scale.py`/`.service`) re-applies the configured scale about
a second after every such change, without confirmation dialogs.

- The target scale and per-resolution overrides live in
  `~/.config/fixed-display-scale.conf` (`scale=2` by default). The installer
  only creates this file when it does not exist, so local tweaks survive
  re-runs. Changes take effect within ~10 seconds; pausing enforcement is
  `enabled=no` in the same file, or `systemctl --user stop
  fixed-display-scale.service`.
- Mutter only accepts scales that produce whole-pixel logical sizes for the
  current mode. 2.0 is exact on both the 4K external (3840x2160) and the
  MacBook panel (3024x1964); on modes where a requested scale is impossible
  (e.g. 1.5 on 3024x1964) the service snaps to the closest supported value.
- Because enforcement is the point, deliberately choosing another scale in
  GNOME Settings gets reverted. Change `scale=` in the config file instead.
- `gnome-settings.sh` enables mutter's `scale-monitor-framebuffer` and
  `xwayland-native-scaling` experimental features; the service re-checks them
  at startup as a safety net.
- The service logs corrections to `~/.local/state/fixed-display-scale.log`.
