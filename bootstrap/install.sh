pacman -Sy --noconfirm --needed git
git clone https://github.com/ryanpcadams/dotfiles.git

bash dotfiles/bootstrap/filesystem.sh
arch-chroot /mnt /home/ryan/dotfiles/bootstrap/user.sh
