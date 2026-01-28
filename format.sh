# Sanitize the device

read -p "Sanitize device $GUIX_DRIVE? (y/n) " answer
if [[ $answer =~ ^[yY] ]]; then
	read -p "WARNING: All data will be irreversibly erased. Do you want to continue? (y/n) " answer
	if [[ $answer =~ ^[yY] ]]; then
		if [[ $GUIX_DRIVE =~ ^\/dev\/nvme[0-9] ]]; then
			if ! command -v nvme >/dev/null 2>&1; then
				guix install nvme-cli
			fi
			
			nvme sanitize-log $GUIX_DRIVE
			
			read -p "Start a Block Erase operation? (y/n) " answer
			if [[ $answer =~ ^[yY] ]]; then
				nvme sanitize $GUIX_DRIVE -a start-block-erase
				
				printf '%s\n' 'Block Erase operation was started in background.' \
							  'You can follow the progress with: nvme sanitize-log $GUIX_DRIVE'
			fi
		else
			blkdiscard $GUIX_DRIVE_FQN
		fi
	fi
fi

# Create boot and system partitions

parted --script $GUIX_DRIVE_FQN -- mklabel gpt \
	mkpart boot fat32 0% 1GiB set 1 esp on \
	mkpart system 1GiB 100% \
	print

# Encrypt system partition

read -p "Encrypt system partition $GUIX_SYST_PART? (y/n) " answer
if [[ $answer =~ ^[yY] ]]; then
	cryptsetup luksFormat --type luks2 --pbkdf pbkdf2 $GUIX_SYST_PART
	cryptsetup open $GUIX_SYST_PART system
	crpytsetup luksDump $GUIX_SYST_PART

	export GUIX_SYST_PART=/dev/mapper/system
fi

# Create file systems

mkfs.fat -F32 $GUIX_BOOT_PART
mkfs.btrfs -L system $GUIX_SYST_PART

# Create subvolumes

mount $GUIX_SYST_PART /mnt

for subvol in @boot @store @guix @log @lib @root @home @keep @swap @snapshots; do
	btrfs subvolume create /mnt/$subvol
done

# Initialize swap

mkdir -p /mnt/swap
mount -o subvol=@swap $GUIX_SYST_PART /mnt/swap
btrfs filesystem mkswapfile --size 4g --uuid clear /mnt/swap/swapfile

umount $GUIX_SYST_PART /mnt
