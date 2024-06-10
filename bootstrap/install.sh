#!/bin/sh

# Luke's Auto Rice Bootstrapping Script (LARBS)
# by Luke Smith <luke@lukesmith.xyz>
# License: GNU GPLv3

### OPTIONS AND VARIABLES ###

# dotfilesrepo="https://github.com/ryanpcadams/dotfiles.git"
# progsfile="https://raw.githubusercontent.com/ryanpcadams/dotfiles/master/bootstrap/programs.csv"
# aurhelper="yay"
# repobranch="master"
# export TERM=ansi

### FUNCTIONS ###
manualinstall() {
  # Installs $1 manually. Used only for AUR helper here.
  # Should be run after repodir is created and var is set.
  pacman -Qq "$1" && return 0
  sudo -u "${user}" mkdir -p "${repodir}/$1"
  sudo -u "${user}" git -C "${repodir}" clone --depth 1 --single-branch --no-tags -q "https://aur.archlinux.org/$1.git" "${repodir}/$1" || 
    {
      cd "${repodir}/$1" || return 1
      sudo -u "${user}" git pull --force origin master
    }
  cd "${repodir}/$1" || exit 1
  sudo -u "${user}" makepkg --noconfirm -si
}


gitmakeinstall() {
  progname="${1##*/}"
  progname="${progname%.git}"
  dir="$repodir/$progname"
  sudo -u "$name" git -C "$repodir" clone --depth 1 --single-branch \
       --no-tags -q "$1" "$dir" ||
       {
         cd "$dir" || return 1
         sudo -u "$name" git pull --force origin master
       }
  cd "$dir" || exit 1
  make >/dev/null 2>&1
  make install >/dev/null 2>&1
  cd /tmp || return 1
}

pipinstall() {
  whiptail --title "Installation" \
           --infobox "Installing the Python package \`$1\` ($n of $total). $1 $2" 9 70
  [ -x "$(command -v "pip")" ] || installpkg python-pip >/dev/null 2>&1
  yes | pip install "$1"
}

installationloop() {
  ([ -f "$progsfile" ] && cp "$progsfile" /tmp/progs.csv) || curl -Ls "$progsfile" | sed '/^#/d' > /tmp/progs.csv
  total=$(wc -l < /tmp/progs.csv)
  aurinstalled=$(pacman -Qqm)
  while IFS=, read -r tag program comment; do
    n=$((n + 1))
    echo "$comment" | grep -q "^\".*\"$" && comment="$(echo "$comment" | sed -E "s/(^\"|\"$)//g")"
    case "$tag" in
      "A") aurinstall "$program" "$comment" ;;
      "G") gitmakeinstall "$program" "$comment" ;;
      "P") pipinstall "$program" "$comment" ;;
      *) pacman --noconfirm --needed -S "$program" "$comment" ;;
    esac
  done < /tmp/progs.csv
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
  # Fix a Vim Vixen bug with dark mode not fixed on upstream:
  # sudo -u "${user}" mkdir -p "$pdir/chrome"
  #[ ! -f  "$pdir/chrome/userContent.css" ] && sudo -u "${user}" echo ".vimvixen-console-frame { color-scheme: light !important; }
#category-more-from-mozilla { display: none !important }" > "$pdir/chrome/userContent.css"
}

### THE ACTUAL SCRIPT ###

# Refresh Arch keyrings.
pacman --noconfirm -S archlinux-keyring # >/dev/null 2>&1

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Set up networking
systemctl enable --now NetworkManager

sed -i 's/^#en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
timedatectl --no-ask-password set-timezone "Europe/London"
timedatectl --no-ask-password set-ntp 1
localectl --no-ask-password set-locale LANG="en_GB.UTF-8" LC_TIME="en_GB.UTF-8"
ln -s /usr/share/zoneinfo/Europe/London /etc/localtime
localectl --no-ask-password set-keymap uk
echo "${HOSTNAME}" > /etc/hostname
sed -i "s/-j2/-j$(nproc)/;/^#MAKEFLAGS/s/^#//" /etc/makepkg.conf
sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
grep -q "ILoveCandy" /etc/pacman.conf || sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf
sed -Ei "s/^#(ParallelDownloads).*/\1 = 5/;/^#Color$/s/#//" /etc/pacman.conf
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
pacman -Sy --noconfirm --needed

# Create user
useradd --home-dir "/home/${user}" -g wheel -s /bin/zsh "${user}" || usermod -a -G wheel "${user}" && chown "${user}:wheel" "/home/${user}"
chown -R "${user}:wheel" "/home/${user}"
echo "${user}:${PASSWORD}" | chpasswd
[ -f /etc/sudoers.pacnew ] && cp /etc/sudoers.pacnew /etc/sudoers # Just in case

export repodir="/home/${user}/.local/src"
manualinstall yay

# Make sure .*-git AUR packages get updated automatically.
# $aurhelper -Y --save --devel

pacman -S --noconfirm --needed - < "/home/${user}/dotfiles/bootstrap/packages/default.txt"
sudo -u "${user}" yay -S --noconfirm --needed - < "/home/${user}/dotfiles/bootstrap/packages/aur.txt"

browserdir="/home/${user}/.librewolf"
profilesini="$browserdir/profiles.ini"
# Start librewolf headless so it generates a profile. Then get that profile in a variable.
# sudo -u "${user}" librewolf --headless >/dev/null 2>&1 &
# sleep 1
# profile="$(sed -n "/Default=.*.default-default/ s/.*=//p" "$profilesini")"
# pdir="$browserdir/$profile"
# [ -d "$pdir" ] && installffaddons
# pkill -u "${user}" librewolf
