mount $ROOTDEVICE /mnt

for subvol in @ @boot @swap @home @store @guix @log @lib @persist; do
	btrfs subvolume create /mnt/$subvol
done

btrfs subvolume snapshot -r /mnt/@ /mnt/@blank

umount $ROOTDEVICE /mnt