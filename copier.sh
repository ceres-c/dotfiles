#!/bin/bash
# Nano syntax highlight
for i in $(ls $HOME/dotfiles/nano); do
	sudo ln -sf $HOME/dotfiles/nano/$i /usr/share/nano/$i
done

# System config
sudo ln -f ./70-persistent-net.rules /etc/udev/rules.d/70-persistent-net.rules # For my USB ethernet adapter
if sudo [ -d "/etc/nfc/" ]; then
	sudo ln -sf $HOME/dotfiles/libnfc.conf /etc/nfc/libnfc.conf # To allow scanning of USB-UART adapters
else
	echo "Libnfc does not seem to be installed. Install it and then run this script again"
fi
sudo ln -sf $HOME/dotfiles/tlp /etc/default/tlp
sudo ln -sf $HOME/dotfiles/intel-undervolt.conf /etc/intel-undervolt.conf # Undervolt config for my XPS 13 9360
if [ -f "/etc/modprobe.d/blacklist-libnfc.conf" ]; then
	sudo ln -sf $HOME/dotfiles/blacklist-libnfc.conf /etc/modprobe.d/blacklist-libnfc.conf # Modprobe offending pn533 modules
else
	echo "Libnfc blacklist rules not found. You might want to install libnfc first to avoid file collisions."
fi

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
if [ ! -d "$HOME/.config/conky/" ]; then
	mkdir $HOME/.config/conky/
fi
ln -sf $HOME/dotfiles/conky.conf $HOME/.config/conky/conky.conf
if [ ! -d "$HOME/.config/pip/" ]; then
	mkdir $HOME/.config/pip/
fi
ln -sf $HOME/dotfiles/pip.conf $HOME/.config/pip/pip.conf
