#!/bin/sh

### FUNCTIONS ###
manualinstall() {
  repodir="/home/${user_name}/.local/src"
  pacman -Qq "$1" && return 0
  sudo -u "${user_name}" mkdir -p "${repodir}/$1"
  sudo -u "${user_name}" git -C "${repodir}" clone --depth 1 --single-branch --no-tags -q "https://aur.archlinux.org/$1.git" "${repodir}/$1" || 
    {
      cd "${repodir}/$1" || return 1
      sudo -u "${user_name}" git pull --force origin master
    }
  cd "${repodir}/$1" || exit 1
  sudo -u "${user_name}" makepkg --noconfirm -si
}

gitmakeinstall() {
  progname="${1##*/}"
  progname="${progname%.git}"
  dir="$repodir/$progname"
  sudo -u "$user_name" git -C "$repodir" clone --depth 1 --single-branch \
       --no-tags -q "$1" "$dir" ||
       {
         cd "$dir" || return 1
         sudo -u "$user_name" git pull --force origin master
       }
  cd "$dir" || exit 1
  make >/dev/null 2>&1
  make install >/dev/null 2>&1
  cd /tmp || return 1
}

vimplugininstall() {
  # Installs vim plugins.
  whiptail --infobox "Installing neovim plugins..." 7 60
  mkdir -p "/home/$name/.config/nvim/autoload"
  curl -Ls "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim" >  "/home/$name/.config/nvim/autoload/plug.vim"
  chown -R "$name:wheel" "/home/$name/.config/nvim"
  sudo -u "$name" nvim -c "PlugInstall|q|q"
}

installffaddons(){
  addonlist="ublock-origin decentraleyes istilldontcareaboutcookies vim-vixen"
  addontmp="$(mktemp -d)"
  trap "rm -fr $addontmp" HUP INT QUIT TERM PWR EXIT
  IFS=' '
  sudo -u "${user}" mkdir -p "$pdir/extensions/"
  for addon in $addonlist; do
    if [ "$addon" = "ublock-origin" ]; then
      addonurl="$(curl -sL https://api.github.com/repos/gorhill/uBlock/releases/latest | grep -E 'browser_download_url.*\.firefox\.xpi' | cut -d '"' -f 4)"
    else
      addonurl="$(curl --silent "https://addons.mozilla.org/en-US/firefox/addon/${addon}/" | grep -o 'https://addons.mozilla.org/firefox/downloads/file/[^"]*')"
    fi
    file="${addonurl##*/}"
    sudo -u "${user}" curl -LOs "$addonurl" > "$addontmp/$file"
    id="$(unzip -p "$file" manifest.json | grep "\"id\"")"
    id="${id%\"*}"
    id="${id##*\"}"
    mv "$file" "$pdir/extensions/$id.xpi"
  done
  chown -R "${user}:${user}" "$pdir/extensions"
}

### THE ACTUAL SCRIPT ###

source "dotfiles/bootstrap/config"

# Refresh Arch keyrings.
pacman --noconfirm -S archlinux-keyring # >/dev/null 2>&1

grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
sed -i 's/^#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# Set up networking
systemctl enable --now NetworkManager

# Set up location based config
sed -i 's/^#en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
timedatectl --no-ask-password set-timezone "Europe/London"
timedatectl --no-ask-password set-ntp 1
localectl --no-ask-password set-locale LANG="en_GB.UTF-8" LC_TIME="en_GB.UTF-8"
ln -s /usr/share/zoneinfo/Europe/London /etc/localtime
localectl --no-ask-password set-keymap uk

# Change host name
old_hostname=$(cat /etc/hostname)
hostnamectl set-hostname $host_name
sudo sed -i "s/$old_hostname/$host_name/g" /etc/hosts
sudo sed -i "s/$old_hostname/$host_name/g" /etc/hostname

# General config
sed -i "s/-j2/-j$(nproc)/;/^#MAKEFLAGS/s/^#//" /etc/makepkg.conf
sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
grep -q "ILoveCandy" /etc/pacman.conf || sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf
sed -Ei "s/^#(ParallelDownloads).*/\1 = 5/;/^#Color$/s/#//" /etc/pacman.conf
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
pacman -Sy --noconfirm --needed

# Create user
useradd --home-dir "/home/${user_name}" -g wheel -s /bin/zsh "${user_name}" || usermod -a -G wheel "${user_name}" && chown "${user_name}:wheel" "/home/${user_name}"
chown -R "${user_name}:wheel" "/home/${user_name}"
echo "${user_name}:${user_pwd}" | chpasswd
[ -f /etc/sudoers.pacnew ] && cp /etc/sudoers.pacnew /etc/sudoers # Just in case

# Install packages
pacman -S --noconfirm --needed - < "/home/${user_name}/dotfiles/bootstrap/packages/default.txt"
manualinstall yay
sudo -u "${user_name}" yay -S --noconfirm --needed - < "/home/${user_name}/dotfiles/bootstrap/packages/aur.txt"

# browserdir="/home/${user}/.librewolf"
# profilesini="$browserdir/profiles.ini"
# Start librewolf headless so it generates a profile. Then get that profile in a variable.
# sudo -u "${user}" librewolf --headless >/dev/null 2>&1 &
# sleep 1
# profile="$(sed -n "/Default=.*.default-default/ s/.*=//p" "$profilesini")"
# pdir="$browserdir/$profile"
# [ -d "$pdir" ] && installffaddons
# pkill -u "${user}" librewolf
