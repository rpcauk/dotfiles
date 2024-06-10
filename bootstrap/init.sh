pacman -Sy --noconfirm --needed git
git clone https://github.com/ryanpcadams/dotfiles.git

DISK="${DISK:-/dev/sda}" bash dotfiles/bootstrap/preinstall.sh

pacman -S --noconfirm --needed stow
mkdir -p /mnt/home/ryan
cp -r dotfiles /mnt/home/ryan
stow --dir=/mnt/home/ryan/dotfiles .

user="${user:-ryan}" PASSWORD="${PASSWORD:-password}" HOSTNAME="${HOSTNAME:-porthpean}" arch-chroot /mnt /home/ryan/dotfiles/bootstrap/install.sh
