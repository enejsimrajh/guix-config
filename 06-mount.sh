mount -t tmpfs none /mnt
mkdir -p /mnt/{boot,boot/efi,gnu/store,var/guix,keep}

mount $GUIX_BOOT_PARTITION /mnt/boot/efi
mount -o subvol=@boot $GUIX_SYSTEM_PARTITION /mnt/boot
mount -o subvol=@store $GUIX_SYSTEM_PARTITION /mnt/gnu/store
mount -o subvol=@guix $GUIX_SYSTEM_PARTITION /mnt/var/guix
mount -o subvol=@keep $GUIX_SYSTEM_PARTITION /mnt/keep
