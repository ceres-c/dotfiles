#!/bin/bash
# Nano syntax highlight
for i in $(ls nano); do
	sudo ln -rsf nano/$i /usr/share/nano/$i
done

# System config
# All USB tty and alike devices rules
sudo ln -rsf 52-usb.rules /etc/udev/rules.d/52-usb.rules
# For USB ethernet adapters
sudo ln -rsf 70-persistent-net.rules /etc/udev/rules.d/70-persistent-net.rules
# Logitech c930 Webcam config applied on boot (brightness + power live frequency)
sudo ln -rsf 99-logitech-c930-video.rules /etc/udev/rules.d/99-logitech-c930-video.rules
# Modprobe offending pn533 modules + psmouse
sudo ln -rsf modprobe.conf /etc/modprobe.d/modprobe.conf
echo "[!] Don't forget to add /etc/modprobe.d/modprobe.conf to your /etc/mkinicpio.conf 'FILES' list"
# Enable bigger font and italian keymap in vConsole
sudo ln -rsf vconsole.conf /etc/vconsole.conf
# Global env vars
sudo ln -rsf environment /etc/environment
# LibNFC settings
if sudo [ -d "/etc/nfc/" ]; then
    # To allow scanning of USB-UART adapters
	sudo ln -rsf libnfc.conf /etc/nfc/libnfc.conf
else
	echo "Libnfc does not seem to be installed. Install it and then run this script again"
fi
# TLP config
sudo ln -rsf tlp /etc/default/tlp
# Undervolt config for my XPS 13 9360
sudo ln -rsf intel-undervolt.conf /etc/intel-undervolt.conf
# Prevent dhcpcd from overwriting Google DNS. As per https://wiki.archlinux.org/index.php/Dhcpcd#/etc/resolv.conf
sudo ln -rsf resolv.conf.head /etc/resolv.conf.head
# Terminator KDE ServiceMenu entry
sudo ln -rsf openTerminatorHere.desktop /usr/share/kservices5/openTerminatorHere.desktop
# Increase number of inotify watchers.
sudo ln -rsf 40-max-user-watches.conf /etc/sysctl.d/40-max-user-watches.conf
# Restore old (possibly dangerous) dmesg nonroot behaviour
sudo ln -rsf 51-dmesg-restrict.conf /etc/sysctl.d/51-dmesg-restrict.conf

# root user config
sudo ln -rsf .tmux.conf /root/.tmux.conf
sudo ln -rsf .tmux /root/.tmux
sudo ln -rsf .zshrc /root/.zshrc
sudo ln -rsf .zpreztorc /root/.zpreztorc
sudo ln -rsf .gitconfig /root/.gitconfig
sudo ln -rsf .pam_environment /root/.pam_environment
if sudo [ ! -d "/root/.config/nano/" ]; then
	sudo mkdir /root/.config/nano/
fi
sudo ln -rsf nanorc /root/.config/nano/nanorc

# Current user config
# PulseAudio config to not fuck up with my docking station
ln -rsf default.pa ~/.config/pulse/default.pa
# Xorg config to unlock gnome-keyring used by vscode on login
ln -rsf .xprofile $HOME/.xprofile
# Miscellaneous user software
if [ ! -d "$HOME/.config/terminator/" ]; then
	mkdir $HOME/.config/terminator/
fi
ln -rsf terminator.conf $HOME/.config/terminator/config
ln -rsf alacritty.yml $HOME/.alacritty.yml
ln -rsf .tmux.conf $HOME/.tmux.conf
ln -rsf .tmux $HOME/.tmux
ln -rsf .zshrc $HOME/.zshrc
ln -rsf .zpreztorc $HOME/.zpreztorc
ln -rsf .gitconfig $HOME/.gitconfig
if [ ! -d "$HOME/.config/nano/" ]; then
	mkdir $HOME/.config/nano/
fi
ln -rsf nanorc $HOME/.config/nano/nanorc
if [ ! -d "$HOME/.config/pip/" ]; then
	mkdir $HOME/.config/pip/
fi
echo "[!] You don't want to use pip with the --user switch anymore. Please do things the right way this time and fix this mess."
echo "	Also, remove the PYTHONPATH export in .zshrc"
ln -rsf pip.conf $HOME/.config/pip/pip.conf
# Pacman hook to fix XPS13 hissing headphones
ln -rsf headphones_hissing.service $HOME/.config/systemd/user/headphones_hissing.service
systemctl --user enable headphones_hissing.service
# start ssh-agent on login
ln -rsf ssh-agent.service $HOME/.config/systemd/user/ssh-agent.service
systemctl --user enable ssh-agent.service
# Enable ssg-agent as the default pam ssh auth service
ln -rsf .pam_environment /root/.pam_environment

if [ ! -d "$HOME/.config/keepassxc/" ]; then
	mkdir $HOME/.config/keepassxc/
fi
ln -rsf keepassxc.ini $HOME/.config/keepassxc/keepassxc.ini
echo "[#] Add relevant SSH keys to ssh-agent in KeepasXC's entry page"

# MPV config for VAAPI
if [ ! -d "$HOME/.config/mpv/" ]; then
    mkdir $HOME/.config/mpv/
fi
ln -rsf mpv.conf $HOME/.config/mpv/mpv.conf
echo "[#] Install intel-media-driver if not already done"
# Chromium config for VAAPI and HiDPI
ln -rsf chromium-flags.conf $HOME/.config/chromium-flags.conf
