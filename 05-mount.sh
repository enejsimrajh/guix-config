mount -t tmpfs none /mnt
mkdir -p /mnt/{boot,boot/efi,gnu/store,var/guix,persist}
mount $BOOTDEVICE /mnt/boot/efi
mount -o subvol=@boot $ROOTDEVICE /mnt/boot
mount -o subvol=@store $ROOTDEVICE /mnt/gnu/store
mount -o subvol=@guix $ROOTDEVICE /mnt/var/guix
mount -o subvol=@persist $ROOTDEVICE /mnt/persist
