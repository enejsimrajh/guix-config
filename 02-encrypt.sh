ROOTDEVICE=/dev/mapper/root

cryptsetup luksFormat --type luks2 --pbkdf pbkdf2 $ROOTPART
cryptsetup open $ROOTPART root