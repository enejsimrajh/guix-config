Before starting, identify the target storage device and set the DISK variable:
$ lsblk
$ export DISK=<target device>

Sanitize, encrypt, and swap steps are optional but recommended.

Reboot and set the password if all the steps have completed successfully:
$ reboot
$ passwd root
