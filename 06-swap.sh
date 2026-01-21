SWAPFILE=/mnt/swap/swapfile

mkdir /mnt/swap
mount -o subvol=@swap $ROOTDEVICE /mnt/swap
btrfs filesystem mkswapfile --size 4g --uuid clear $SWAPFILE
swapon $SWAPFILE