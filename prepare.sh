# Mount required file systems

mount -t tmpfs none /mnt
mkdir -p /mnt/{boot,boot/efi,gnu/store,var/guix,keep}

mount -o subvol=@boot $GUIX_SYST_PART /mnt/boot
mount -o subvol=@store $GUIX_SYST_PART /mnt/gnu/store
mount -o subvol=@guix $GUIX_SYST_PART /mnt/var/guix
mount -o subvol=@keep $GUIX_SYST_PART /mnt/keep
mount $GUIX_BOOT_PART /mnt/boot/efi

# Copy config file to target device

configdir=/mnt/keep/etc
export GUIX_CONFIGFILE="$configdir"/config.scm

mkdir -p $configdir
cp -i config.scm $GUIX_CONFIGFILE

printf '%s\n' 'Configuration file was copied to the target storage device.' \
			  'You can edit the configuration with: emacs $GUIX_CONFIGFILE'