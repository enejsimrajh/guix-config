# Create file systems
mkfs.fat -F32 $GUIX_BOOT_PARTITION
mkfs.btrfs -m single -L root $GUIX_SYSTEM_PARTITION

# Create subvolumes
mount $GUIX_SYSTEM_PARTITION /mnt
for subvol in @boot @store @guix @log @lib @root @home @keep @snapshots; do
	btrfs subvolume create /mnt/$subvol
done
umount $GUIX_SYSTEM_PARTITION /mnt
