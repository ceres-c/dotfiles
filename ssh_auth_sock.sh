#! /bin/sh
# Export ssh-agent's socket when systemd socket activation set it up.
#
# Debian's socket-activated OpenSSH agent listens on
# /run/user/$UID/openssh_agent. Don't clobber an agent already started by GNOME.
if [ -z "${SSH_AUTH_SOCK:-}" ] && [ -n "${XDG_RUNTIME_DIR:-}" ]; then
	if [ -S "${XDG_RUNTIME_DIR}/openssh_agent" ]; then
		export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR}/openssh_agent"
	fi
fi
