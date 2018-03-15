#!/bin/bash
for i in $(ls $HOME/dotfiles/nano); do
	sudo ln -sf $HOME/dotfiles/nano/$i /usr/share/nano/$i
done

sudo ln -f ./70-persistent-net.rules /etc/udev/rules.d/70-persistent-net.rules
sudo ln -sf $HOME/dotfiles/libnfc.conf /etc/nfc/libnfc.conf
sudo ln -sf $HOME/dotfiles/tlp /etc/default/tlp
ln -sf $HOME/dotfiles/.tmux.conf $HOME/.tmux.conf
ln -sf $HOME/dotfiles/.zshrc $HOME/.zshrc
ln -sf $HOME/dotfiles/.gitconfig $HOME/.gitconfig
ln -sf $HOME/dotfiles/nanorc $HOME/.config/nano/nanorc
ln -sf $HOME/dotfiles/conky.conf $HOME/.config/conky/conky.conf
