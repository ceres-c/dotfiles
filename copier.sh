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
# Modprobe offending pn533 modules + psmouse
sudo ln -rsf modprobe.conf /etc/modprobe.d/modprobe.conf
# Enable bigger font and italian keymap in vConsole
sudo ln -rsf vconsole.conf /etc/vconsole.conf
# Global env vars
sudo ln -rsf environment /etc/environment
# Pacman hook to fix XPS13 hissing headphones
sudo ln -rsf headphones_hissing.hook /usr/share/libalpm/hooks/headphones_hissing.hook
echo "[!] Don't forget to add /etc/modprobe.d/modprobe.conf to your /etc/mkinicpio.conf 'FILES' list"
if sudo [ -d "/etc/nfc/" ]; then
    # To allow scanning of USB-UART adapters
	sudo ln -rsf libnfc.conf /etc/nfc/libnfc.conf
else
	echo "Libnfc does not seem to be installed. Install it and then run this script again"
fi
sudo ln -rsf tlp /etc/default/tlp
# Undervolt config for my XPS 13 9360
sudo ln -rsf intel-undervolt.conf /etc/intel-undervolt.conf
# Prevent dhcpcd from overwriting Google DNS. As per https://wiki.archlinux.org/index.php/Dhcpcd#/etc/resolv.conf
sudo ln -rsf resolv.conf.head /etc/resolv.conf.head
# Terminator KDE ServiceMenu entry
sudo ln -rsf openTerminatorHere.desktop /usr/share/kservices5/openTerminatorHere.desktop
# Increase number of inotify watchers. Done with tee as echo was dropped privileges befor writing
echo fs.inotify.max_user_watches=524288 | sudo tee /etc/sysctl.d/40-max-user-watches.conf > /dev/null

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
ln -rsf .pam_environment /root/.pam_environment
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

# MPV config for VAAPI
if [ ! -d "$HOME/.config/mpv/" ]; then
    mkdir $HOME/.config/mpv/
fi
echo "[#] Install intel-media-driver if not already done"
ln -rsf mpv.conf $HOME/.config/mpv/mpv.conf
