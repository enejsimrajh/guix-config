#!/bin/bash
# guix-system-install: Automate Guix System installation
#
# Copyright © 2024 Giovanni Biscuolo <g@xelera.eu>
# Copyright © 2026 Enej Simrajh
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

# The purpose of this script is to document the installation process
# and to automate any future installations of Guix System. The script
# is intended for use on a host booted with Guix Installer using the
# manual installation method.

# ---------------------------------------------------------------------
# UTILITIES

_msg() {
    printf "[%s]: %s\n" "$(date +%s.%3N)" "$1"
}

_msg_pass() {
    _msg "[ PASS ] $1"
}

_msg_warn() {
    _msg "[ WARN ] $1"
}

_msg_info() {
    _msg "[ INFO ] $1"
}

_err() {
    printf "[%s]: ${ERR}%s\n" "$(date +%s.%3N)" "$1"
}

die() {
    _err "$*"
    exit 1
}

# Return true if user answered yes, false otherwise. The prompt is
# yes-biased, that is, when the user simply enters newline, it is
# equivalent to answering "yes".
# $1: The prompt question.
prompt_yes_no() {
    local -l yn=""
    read -rp "$1 [Y/n] " yn
    [[ ! $yn || $yn = y || $yn = yes ]] || return 1
}

# $1: The command.
chk_cmd() {
    command -v $1 >/dev/null 2>&1 || return 1
}

# ---------------------------------------------------------------------
# VARIABLES

# Used variables MUST ALWAYS be initialized.
set -o nounset

# Source variables from installaton config file if it exixts.
: ${INSTALL_CONFIG_FILE:="guix-system-install.conf.sh"}
if [[ -e $INSTALL_CONFIG_FILE ]]; then
    source ./$INSTALL_CONFIG_FILE
    _msg_info "Found $INSTALL_CONFIG_FILE: sourced."
fi

# Persistence options
: ${TARGET_DISK:=""}                        # linux block device name (e.g. "sda", "nvme0n1", ...)
: ${TARGET_DISK_ENCRYPTION:="none"}          # encryption scheme: none | full
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

# Non-configurable variables
TARGET_DISK_PATH=""                         # linux device node path: /dev/$TARGET_DISK
TARGET_DISK_PART_PREFIX=""                  # partition prefix, inferred from TARGET_DISK

TARGET_HOST_BOOT_FW=""                      # boot firmware: bios | uefi

TARGET_BOOT_DEVICE=""                       #
TARGET_OS_DEVICE=""                         #

# ---------------------------------------------------------------------
# VALIDATION

# Ensure valid target disk name is set
while [[ ! $TARGET_DISK =~ ^((s|v)d[a-z]|nvme[0-9]n[0-9]|mmcblk[0-9])$ ]] ; do
    if [[ -n $TARGET_DISK ]]; then
        _msg_warn "Unsupported storage device: $TARGET_DISK"
    fi
    lsblk --list --output name,model,serial,label,type | grep --color=never disk
    read -p "Select target storage device (e.g. "sda", "nvme0n1", ...): " TARGET_DISK
done

TARGET_DISK_PATH=/dev/$TARGET_DISK

# Ensure valid encryption scheme is set
while [[ ! $TARGET_DISK_ENCRYPTION =~ ^(none|full)$ ]] ; do
    _msg_warn "Unsupported encryption scheme: $TARGET_DISK_ENCRYPTION"
    read -p "Select target encryption scheme [none/full]: " TARGET_DISK_ENCRYPTION
done

# TODO: validate other inputs

# Infer partition prefix from disk type
case $TARGET_DISK in
    nvme*n* | mmcblk*)  TARGET_DISK_PART_PREFIX="p";;
    sd* | vd*)          TARGET_DISK_PART_PREFIX="";;
    *)                  die "Could not infer partition prefix for selected storage device.";;
esac

# Infer boot firmware from UEFI firmware presence
if [[ -e "/sys/firmware/efi/efivars" ]]; then
    TARGET_HOST_BOOT_FW="uefi"
else
    TARGET_HOST_BOOT_FW="bios"
fi


# Print installation parameters for review and confirmation
_msg_info "Installation parameters were set."
echo "Hostname.........................: $TARGET_HOST_NAME"
echo "Virtual machine?.................: $TARGET_HOST_IS_VM"
echo "Boot firmware....................: $TARGET_HOST_BOOT_FW"
echo "Storage device...................: $TARGET_DISK"
echo "Encryption scheme................: $TARGET_DISK_ENCRYPTION"
echo "Swap size........................: $TARGET_DISK_SWAP_SIZE"
echo "User name........................: $TARGET_USER_NAME"
echo "User comment.....................: $TARGET_USER_COMMENT"
echo "User public key..................: $TARGET_USER_KEY"
echo "OS configuration file............: $TARGET_OS_CONFIG_FILE"
echo "OS mount point...................: $TARGET_OS_MOUNT_POINT"
echo "OS device label..................: $TARGET_OS_DEVICE_LABEL"
_msg_warn "Please check the configured installation parameters."
prompt_yes_no "Do you want to continue with installation?" || exit 1

# --------------------------------------------------------------------
# DISK FORMATTING

# Abort on any error from now on
set -eo pipefail

# $1: Nvme device node path.
sanitize_nvme() {
    local -l target=${1%??}

    if ! chk_cmd nvme; then
        guix install nvme-cli
	fi

	nvme sanitize-log $target | grep --color=never "Block Erase"
    _msg_warn "Please check the estimated duration of sanitization."

	if prompt_yes_no "Start a Block Erase operation? This may take a very long time."; then
		nvme sanitize $target -a start-block-erase
		_msg_info "Block Erase operation was started in background."
		_msg_info "Wait for the process to finish, then restart your system, \
resume the installation, and continue without sanitization."
		_msg_info "You can follow the progress with: nvme sanitize-log $target"
		exit 0
	fi
}

# Sanitize the disk
if prompt_yes_no "Sanitize device $TARGET_DISK_PATH?"; then
	_msg_warn "All data will be irreversibly erased."
	if prompt_yes_no "Do you want to continue?"; then
	    case $TARGET_DISK in
			nvme*n*)    sanitize_nvme $TARGET_DISK_PATH;;
			*)          blkdiscard $TARGET_DISK_PATH
		esac
	fi
fi

# Partition the disk
_msg_info "Partitioning $TARGET_DISK_PATH ..."
case $TARGET_HOST_BOOT_FW in
    bios)
        ;; # TODO
    uefi)
        parted $TARGET_DISK_PATH --align=opt -s -- \
            mklabel gpt \
            mkpart boot fat32 0% $TARGET_DISK_ESP_SIZE set 1 esp on \
            mkpart $TARGET_OS_DEVICE_LABEL 1GiB 100%
        TARGET_BOOT_DEVICE="$TARGET_DISK_PATH""$TARGET_DISK_PART_PREFIX"1
        TARGET_OS_DEVICE="$TARGET_DISK_PATH""$TARGET_DISK_PART_PREFIX"2
        ;;
esac
parted $TARGET_DISK_PATH print
_msg_pass "$TARGET_DISK_PATH was partitioned."

# Reread partition table
_msg_info "Rereading partition table ..."
partprobe $TARGET_DISK_PATH
_msg_info "Waiting 5 seconds ..."
sleep 5s # Needed sometimes to allow new partition access

# Encrypt disk
case $TARGET_DISK_ENCRYPTION in
    full)
        _msg_info "Encrypting system partition ..."
        cryptsetup luksFormat --type luks2 --pbkdf pbkdf2 $TARGET_OS_DEVICE
    	cryptsetup open $TARGET_OS_DEVICE $TARGET_OS_DEVICE_LABEL
    	cryptsetup luksDump $TARGET_OS_DEVICE
        TARGET_OS_DEVICE=/dev/mapper/$TARGET_OS_DEVICE_LABEL
        _msg_pass "System partition was encrypted."
        ;;
    home)
        # TODO
        ;;
esac

# Initialize file systems
_msg_info "Initializing file systems ..."
if [[ $TARGET_HOST_BOOT_FW = uefi && -n $TARGET_BOOT_DEVICE ]]; then
    mkfs.fat -F32 $TARGET_BOOT_DEVICE
fi
mkfs.btrfs -L $TARGET_OS_DEVICE_LABEL $TARGET_OS_DEVICE
_msg_pass "File systems were initialized."

# Mount OS device
mkdir -p $TARGET_OS_MOUNT_POINT
mount $TARGET_OS_DEVICE $TARGET_OS_MOUNT_POINT

# Create subvolumes
_msg_info "Creating subvolumes ..."
for subvol in @boot @store @guix @log @lib @root @home @keep @swap @snapshots; do
	btrfs subvolume create $TARGET_OS_MOUNT_POINT/$subvol
done
_msg_pass "Subvolumes were created."

# Initialize swap file
_msg_info "Initializing swap file ..."
mkdir $TARGET_OS_MOUNT_POINT/swap
mount -o subvol=@swap $TARGET_OS_DEVICE $TARGET_OS_MOUNT_POINT/swap
btrfs filesystem mkswapfile \
    --size $TARGET_DISK_SWAP_SIZE \
    --uuid clear \
    $TARGET_OS_MOUNT_POINT/swap/swapfile
_msg_pass "Swap file was initialized."

# Unmount OS device
umount -R $TARGET_OS_DEVICE $TARGET_OS_MOUNT_POINT

# --------------------------------------------------------------------
# CONFIGURATION GENERATION

TARGET_OS_DEVICE_UUID=$(blkid -o value -s UUID -L $TARGET_OS_DEVICE_LABEL)
TARGET_BOOT_DEVICE_UUID=$(blkid -o value -s UUID $TARGET_BOOT_DEVICE)

CONFIG_INITRD=""
if $TARGET_HOST_IS_VM; then
    CONFIG_INITRD="(initrd-modules (append '(\"virtio_scsi\") %base-initrd-modules))"
fi

CONFIG_BOOTLOADER=""
CONFIG_FS_EFI=""
if [[ $TARGET_HOST_BOOT_FW = uefi ]]; then
    CONFIG_BOOTLOADER="
        (bootloader (bootloader-configuration
                        (bootloader grub-efi-bootloader)
                        (targets '(\"/boot/efi\"))))"
    CONFIG_FS_EFI="
        (file-system
            (device (uuid \"$TARGET_BOOT_DEVICE_UUID\" 'fat))
            (mount-point \"/boot/efi\")
            (type \"vfat\"))"
else
    CONFIG_BOOTLOADER="
        (bootloader (bootloader-configuration
                        (bootloader grub-bootloader)
                        (targets '(\"$TARGET_DISK_PATH\"))))"
fi

CONFIG_MAPPED_DEVICES=""
CONFIG_FS_DEPENDENCIES=""
if [[ $TARGET_DISK_ENCRYPTION = "full" ]]; then
	CONFIG_MAPPED_DEVICES="
	(mapped-devices (list
          (mapped-device
           (source (uuid \"$TARGET_OS_DEVICE_UUID\"))
           (target \"$TARGET_OS_DEVICE_LABEL\")
           (type luks-device-mapping))))"
    CONFIG_FS_DEPENDENCIES="(dependencies mapped-devices)"
fi

_msg_info "Generating configuration file ..."
if ! chk_cmd envsubst; then
    guix install gettext
fi

config_dir=$TARGET_OS_MOUNT_POINT/keep/etc
config_file=$config_dir/config.scm
mkdir -p $config_dir
mount -o subvol=@keep,noatime $TARGET_OS_DEVICE $TARGET_OS_MOUNT_POINT/keep

export TARGET_OS_DEVICE_LABEL
export CONFIG_INITRD
export CONFIG_BOOTLOADER
export CONFIG_MAPPED_DEVICES
export CONFIG_FS_DEPENDENCIES $CONFIG_FS_EFI
export TARGET_USER_NAME $TARGET_USER_COMMENT
envsubst < $TARGET_OS_CONFIG_FILE > $config_file

_msg_pass "Configuration file was generated at $config_file."
_msg_warn "Please check the generated configuration file."
prompt_yes_no "Do you want to continue with installation?" || exit 1

# --------------------------------------------------------------------
# SYSTEM INITIALIZATION

mount -t tmpfs none $TARGET_OS_MOUNT_POINT
mkdir -p $TARGET_OS_MOUNT_POINT/{boot/efi,gnu/store,var/guix}

mount -o subvol=@boot,noatime $TARGET_OS_DEVICE $TARGET_OS_MOUNT_POINT/boot
mount -o subvol=@store,noatime,ro,compress=zstd:1 $TARGET_OS_DEVICE $TARGET_OS_MOUNT_POINT/gnu/store
mount -o subvol=@guix,noatime,compress=zstd:1 $TARGET_OS_DEVICE $TARGET_OS_MOUNT_POINT/var/guix
mount $TARGET_BOOT_DEVICE $TARGET_OS_MOUNT_POINT/boot/efi

herd start cow-store $TARGET_OS_MOUNT_POINT

signing_key="nonguix-signing-key.pub"
wget -O $signing_key https://nonguix-proxy.ditigal.xyz/signing-key.pub
guix archive --authorize < $signing_key

substitutes="https://ci.guix.gnu.org\
 https://bordeaux.guix.gnu.org\
 https://nonguix-proxy.ditigal.xyz"
guix pull --substitute-urls="$substitutes" && hash guix
guix system init --substitute-urls="$substitutes" $config_file $TARGET_OS_MOUNT_POINT
