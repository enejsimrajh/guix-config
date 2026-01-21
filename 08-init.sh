guix pull && hash guix || exit 1
guix system init $CONFIGFILE /mnt || exit 1
reboot