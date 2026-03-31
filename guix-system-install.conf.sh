# Persistence options
: ${TARGET_DISK:=""}                        # linux block device name (e.g. "sda", "nvme0n1", ...)
: ${TARGET_DISK_ENCRYPTION:="none"}          # encryption scheme, options: none, full
: ${TARGET_DISK_SWAP_SIZE:="4G"}            # swapfile size in BTRFS units
: ${TARGET_DISK_ESP_SIZE="1GiB"}            # EFI system partition size in GNU Parted units

# Machine info
: ${TARGET_HOST_NAME:="guix-host"}          #
: ${TARGET_HOST_IS_VM:=false}               # is target a virtual machine?

# Default user info
: ${TARGET_USER_NAME:="user"}               #
: ${TARGET_USER_COMMENT:="Generic user"}    #
: ${TARGET_USER_KEY:=""}                    # public ssh key

# Installation environment options
: ${TARGET_OS_CONFIG_FILE:="config.scm"}    # default OS configuration file
: ${TARGET_OS_MOUNT_POINT:="/mnt/guix"}     # OS mount point
: ${TARGET_OS_DEVICE_LABEL:="guix"}         # OS device label
