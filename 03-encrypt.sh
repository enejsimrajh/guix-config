cryptsetup luksFormat --type luks2 --pbkdf pbkdf2 $ROOTDEVICE
cryptsetup open $ROOTDEVICE root
crpytsetup luksDump $ROOTDEVICE

export ROOTDEVICE=/dev/mapper/root
