export CONFIGFILE=/mnt/persist/etc/guix/config.scm

herd start cow-store /mnt

mkdir -p /mnt/persist/etc/guix
cp /etc/configuration/lightweight-desktop.scm $CONFIGFILE
emacs $CONFIGFILE
