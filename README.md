# Debian GNOME Parallels dotfiles

This branch is for the Debian GNOME guest in Parallels. It is not a cross-distro
or macOS-host installer.

Run `./copier.sh` from the cloned repository. It installs the shell and terminal
tools, Prezto/Powerlevel10k, Terminator, the Parallels keyboard remaps, Desktop
Icons NG, and Dash to Dock, then applies the GNOME preferences.

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
