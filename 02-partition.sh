export BOOTDEVICE="$DISK"p1
export ROOTDEVICE="$DISK"p2

parted --script $DISK -- mklabel gpt \
	mkpart boot fat32 0% 1GiB set 1 esp on \
	mkpart root 1GiB 100% \
	print
