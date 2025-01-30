#!/bin/bash
#
sudo apt install zsh git kitty-terminfo
cd /home/sysmin/linux-vm-defaults/
tar xfvz oh-my-zsh.tar.gz
rm oh-my-zsh.tar.gz
mv .oh-my-zsh /home/sysmin/
mkdir /home/sysmin/.config
mv zsh /home/sysmin/.config/zsh
ln -s /home/sysmin/.config/zsh/zshrc /home/sysmin/.zshrc
sudo cp -r /home/sysmin/.oh-my-zsh /root/
sudo cp /home/sysmin/.config/zsh/zshrc /root/.zshrc
sudo usermod --shell /bin/zsh root
sudo usermod --shell /bin/zsh sysmin
