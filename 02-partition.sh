parted --script $GUIX_DRIVE -- mklabel gpt \
	mkpart boot fat32 0% 1GiB set 1 esp on \
	mkpart system 1GiB 100% \
	print
