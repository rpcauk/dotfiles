#!/bin/bash

# Pacman config
grep -q "ILoveCandy" /etc/pacman.conf || sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf
sed -Ei "s/^#(ParallelDownloads).*/\1 = 5/;/^#Color$/s/#//" /etc/pacman.conf
pacman -Syy

# Required packages for setup
#pacman -S --noconfirm --needed curl ca-certificates base-devel git ntp zsh archlinux-keyring reflector rsync grub gptfdisk btrfs-progs glibc

# Set up mirrors
iso=$(curl -4 ifconfig.co/country-iso)
timedatectl set-ntp true
# pacman -S --noconfirm archlinux-keyring
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
# pacman -S --noconfirm --needed reflector
reflector -a 48 -c $iso -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist

# pacman -S --noconfirm --needed gptfdisk
mkdir /mnt &>/dev/null # Hiding error message if any
umount -A --recursive /mnt
sgdisk -Z ${DISK} # zap all on disk
sgdisk -a 2048 -o ${DISK} # new gpt disk 2048 alignment
# sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:'BIOSBOOT' ${DISK}
sgdisk -n 1::+300M --typecode=1:ef00 --change-name=1:'BOOT' ${DISK}
sgdisk -n 2::+24G --typecode=2:8200 --change-name=2:'SWAP' ${DISK}
sgdisk -n 3::+25G --typecode=3:8304 --change-name=3:'ROOT' ${DISK}
sgdisk -n 4::-0 --typecode=4:8302 --change-name=4:'HOME' ${DISK}
if [[ ! -d "/sys/firmware/efi" ]]; then # Checking for bios system
    sgdisk -A 1:set:2 ${DISK}
fi
partprobe ${DISK} # reread partition table to ensure it is correct
mkfs.fat -F 32 "${DISK}1"
mkswap "${DISK}2"
mkfs.ext4 "${DISK}3"
mkfs.ext4 "${DISK}4"

mount "${DISK}3" /mnt
swapon "${DISK}2"
mount --mkdir "${DISK}1" /mnt/boot
mount --mkdir "${DISK}4" /mnt/home


pacstrap /mnt base base-devel linux linux-firmware networkmanager
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist
genfstab -L /mnt >> /mnt/etc/fstab

loadkeys uk
