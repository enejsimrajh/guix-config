cryptsetup luksFormat --type luks2 --pbkdf pbkdf2 $GUIX_SYSTEM_PARTITION
cryptsetup open $GUIX_SYSTEM_PARTITION system
crpytsetup luksDump $GUIX_SYSTEM_PARTITION

export GUIX_SYSTEM_PARTITION=/dev/mapper/system
