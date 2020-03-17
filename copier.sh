#!/bin/bash
# Nano syntax highlight
for i in $(ls nano); do
	sudo ln -rsf nano/$i /usr/share/nano/$i
done

# System config
sudo ln -rf 52-usb.rules /etc/udev/rules.d/52-usb.rules							# All USB tty and alike devices rules
sudo ln -rf 70-persistent-net.rules /etc/udev/rules.d/70-persistent-net.rules	# For USB ethernet adapters
sudo ln -rsf modprobe.conf /etc/modprobe.d/modprobe.conf						# Modprobe offending pn533 modules + psmouse
sudo ln -rf vconsole.conf /etc/vconsole.conf									# Enable bigger font and italian keymap in vConsole
sudo ln -rf environment /etc/environment										# Global env vars
sudo ln -f headphones_hissing.hook /etc/pacman.d/hooks/headphones_hissing.hook	# Pacman hook to fix XPS13 hissing headphones
echo "[!] Don't forget to add /etc/modprobe.d/modprobe.conf to your /etc/mkinicpio.conf 'FILES' list"
if sudo [ -d "/etc/nfc/" ]; then
	sudo ln -rsf libnfc.conf /etc/nfc/libnfc.conf								# To allow scanning of USB-UART adapters
else
	echo "Libnfc does not seem to be installed. Install it and then run this script again"
fi
sudo ln -rsf tlp /etc/default/tlp
sudo ln -rsf intel-undervolt.conf /etc/intel-undervolt.conf						# Undervolt config for my XPS 13 9360
sudo ln -f default.pa ~/.config/pulse/default.pa								# PulseAudio config to not fuck up with my docking station

# root user config
sudo ln -rsf .tmux.conf /root/.tmux.conf
sudo ln -rsf .tmux /root/.tmux
sudo ln -rsf .zshrc /root/.zshrc
sudo ln -rsf .zpreztorc /root/.zpreztorc
sudo ln -rsf .gitconfig /root/.gitconfig
if sudo [ ! -d "/root/.config/nano/" ]; then
	sudo mkdir /root/.config/nano/
fi
sudo ln -rsf nanorc /root/.config/nano/nanorc

# Current user config
mkdir "$HOME/.config/terminator/"
ln -rsf terminator.conf $HOME/.config/terminator/config
ln -rf openTerminatorHere.desktop $HOME/.local/share/kservices5/ServiceMenus/openTerminatorHere.desktop
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
echo "[!] You don't want to use pip with the --user switch anymore. Please do things the right way this time and fix this mess.\nAlso, remove the PYTHONPATH export in .zshrc"
ln -rsf pip.conf $HOME/.config/pip/pip.conf

# Increase number of inotify watchers
echo fs.inotify.max_user_watches=524288 | sudo tee /etc/sysctl.d/40-max-user-watches.conf

# MPV config for VAAPI
if [ ! -d "$HOME/.config/mpv/" ]; then
    mkdir $HOME/.config/mpv/
fi
echo "[#] Install `intel-media-driver` if not already done"
ln -rsf mpv.conf $HOME/.config/mpv/mpv.conf
