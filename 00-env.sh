# Set guix variables
echo 'GUIX_PROFILE="$HOME/.guix-profile"' >> ~/.bash_profile
echo 'source "$GUIX_PROFILE/etc/profile"' >> ~/.bash_profile
source ~/.bash_profile

# Set storage device variables
lsblk
read -p "Select target storage device: " drive
export GUIX_DRIVE=$drive
export GUIX_BOOT_PARTITION="$drive"p1
export GUIX_SYSTEM_PARTITION="$drive"p2
