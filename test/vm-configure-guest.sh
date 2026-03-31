# mount shared folder
mkdir -p /mnt/guix-config
sudo mount -t 9p -o trans=virtio guix-config /mnt/guix-config

# bind host/guest user id for passthrough permissions
guix install bindfs
sudo bindfs --map=501/1000 /mnt/shared /mnt/shared
