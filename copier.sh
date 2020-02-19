#!/bin/bash
# Nano syntax highlight
for i in $(ls $HOME/dotfiles/nano); do
	sudo ln -sf $HOME/dotfiles/nano/$i /usr/share/nano/$i
done

# System config
sudo ln -f ./52-usb.rules /etc/udev/rules.d/52-usb.rules						# All USB tty and alike devices rules
sudo ln -f ./70-persistent-net.rules /etc/udev/rules.d/70-persistent-net.rules	# For USB ethernet adapters
sudo ln -sf $HOME/dotfiles/modprobe.conf /etc/modprobe.d/modprobe.conf			# Modprobe offending pn533 modules + psmouse
sudo ln -f ./vconsole.conf /etc/vconsole.conf									# Enable bigger font and italian keymap in vConsole
sudo ln -f ./environment /etc/environment										# Global env vars
sudo ln -f headphones_hissing.hook /etc/pacman.d/hooks/headphones_hissing.hook	# Pacman hook to fix XPS13 hissing headphones
echo "[!] Don't forget to add /etc/modprobe.d/modprobe.conf to your /etc/mkinicpio.conf 'FILES' list"
if sudo [ -d "/etc/nfc/" ]; then
	sudo ln -sf $HOME/dotfiles/libnfc.conf /etc/nfc/libnfc.conf			# To allow scanning of USB-UART adapters
else
	echo "Libnfc does not seem to be installed. Install it and then run this script again"
fi
sudo ln -sf $HOME/dotfiles/tlp /etc/default/tlp
sudo ln -sf $HOME/dotfiles/intel-undervolt.conf /etc/intel-undervolt.conf		# Undervolt config for my XPS 13 9360

# root user config
sudo ln -sf $HOME/dotfiles/.tmux.conf /root/.tmux.conf
sudo ln -sf $HOME/dotfiles/.zshrc /root/.zshrc
sudo ln -sf $HOME/dotfiles/.gitconfig /root/.gitconfig
if sudo [ ! -d "/root/.config/nano/" ]; then
	sudo mkdir /root/.config/nano/
fi
sudo ln -sf $HOME/dotfiles/nanorc /root/.config/nano/nanorc

# Current user config
if [ -d "$HOME/.config/terminator/" ]; then
	ln -sf $HOME/dotfiles/terminator.conf $HOME/.config/terminator/config
	ln -f ./openTerminatorHere.desktop $HOME/.local/share/kservices5/ServiceMenus/openTerminatorHere.desktop
else
	echo "Terminator does not seem to be installed. Install it and then run this script again"
fi
ln -sf $HOME/dotfiles/.tmux.conf $HOME/.tmux.conf
ln -sf $HOME/dotfiles/.zshrc $HOME/.zshrc
ln -sf $HOME/dotfiles/.gitconfig $HOME/.gitconfig
if [ ! -d "$HOME/.config/nano/" ]; then
	mkdir $HOME/.config/nano/
fi
ln -sf $HOME/dotfiles/nanorc $HOME/.config/nano/nanorc
if [ ! -d "$HOME/.config/pip/" ]; then
	mkdir $HOME/.config/pip/
fi
echo "[!] You don't want to use pip with the --user switch anymore. Please do things the right way this time and fix this mess.\nAlso, remove the PYTHONPATH export in .zshrc"
ln -sf $HOME/dotfiles/pip.conf $HOME/.config/pip/pip.conf

# Increase number of inotify watchers
echo fs.inotify.max_user_watches=524288 | sudo tee /etc/sysctl.d/40-max-user-watches.conf

# MPV config for VAAPI
if [ ! -d "$HOME/.config/mpv/" ]; then
    mkdir $HOME/.config/mpv/
fi
echo "[#] Install `intel-media-driver` if not already done"
ln -sf $HOME/dotfiles/mpv.conf $HOME/.config/mpv/mpv.conf
