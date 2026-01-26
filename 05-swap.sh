swapdir=/mnt/swap
export GUIX_SWAPFILE="$swapdir"/swapfile

mount $GUIX_SYSTEM_PARTITION /mnt

btrfs subvolume create /mnt/@swap
mkdir -p $swapdir

mount -o subvol=@swap $GUIX_SYSTEM_PARTITION $swapdir
btrfs filesystem mkswapfile --size 4g --uuid clear $GUIX_SWAPFILE
swapon $GUIX_SWAPFILE

umount $GUIX_SYSTEM_PARTITION /mnt
