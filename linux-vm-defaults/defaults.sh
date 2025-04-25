#!/bin/bash
#
sudo apt install zsh git kitty-terminfo zsh-autosuggestions zsh-syntax-highlighting
cd /opt/ecmacom/linux-vm-defaults/
sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"
mkdir /home/sysmin/.config
cp -r zsh /home/sysmin/.config/zsh
rm /home/sysmin/.zshrc
rm /root/.zshrc
ln -s /home/sysmin/.config/zsh/zshrc /home/sysmin/.zshrc
sudo cp -r /home/sysmin/.oh-my-zsh /root/
sudo cp /home/sysmin/.config/zsh/zshrc /root/.zshrc
sudo usermod --shell /bin/zsh root
sudo usermod --shell /bin/zsh sysmin
