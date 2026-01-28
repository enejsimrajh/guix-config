# Set guix variables

mkdir -p $HOME/.guix-profile/etc/profile

echo 'GUIX_PROFILE="$HOME/.guix-profile"' >>~/.bash_profile
echo 'source "$GUIX_PROFILE/etc/profile"' >>~/.bash_profile

source ~/.bash_profile

# Set storage device variables


while [[ -z "$GUIX_DRIVE" ]]; do
	lsblk
	read -p "Select target storage device: " drive
	
	drive_fqn=drive
	part_prefix=""
	
	if [[ $drive =~ ^\/dev\/sd[a-z] ]]; then
		# defaults are ok for sd devices
	elif [[ $drive =~ ^\/dev\/mmcblk[0-9] ]]; then
		part_prefix="p"
	elif [[ $drive =~ ^\/dev\/nvme[0-9] ]]; then
		part_prefix="p"
		read -p "Select nvme namespace (n#): " ns
		drive_fqn="$drive""$ns"
	else
		printf '%s\n' "Selected device is not supported."
		continue
	fi
	
	export GUIX_DRIVE=$drive
	export GUIX_DRIVE_FQN=$drive_fqn
	export GUIX_BOOT_PART="$drive_fqn""$part_prefix"1
	export GUIX_SYST_PART="$drive_fqn""$part_prefix"2
done
