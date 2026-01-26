configdir=/mnt/keep/etc
export GUIX_CONFIGFILE="$configdir"/config.scm

herd start cow-store /mnt

mkdir -p $configdir
cp /etc/configuration/lightweight-desktop.scm $GUIX_CONFIGFILE
emacs $GUIX_CONFIGFILE
