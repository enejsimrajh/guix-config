Installation procedure:

1. Insert the installation medium and boot into the installer image.
On Tongfang GX4, the boot menu is accessed by pressing F2 repeatedly on startup.

2. Select the installation OS in the GRUB menu.

3. Switch to tty3 by pressing Ctrl+Alt+F3.
If using HiDPI display, double the font size:
$ setfont -d

4. Clone the repository and run scripts in the following order:
$ . setenv.sh
$ . format.sh
$ . prepare.sh
$ . install.sh

5. Shutdown and remove the installation medium:
$ shutdown

6. Now you can boot into the OS and set the passwords:
$ passwd root
$ passwd <user>
