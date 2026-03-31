;; -*- mode: scheme; -*-
;; This is a minimal operating system configuration template
;; intended for use by guix-system-install.sh when initializing
;; the system.

(use-modules (gnu) (gnu system nss))
(use-modules (nongnu packages linux)
	     (nongnu system linux-initrd))
(use-service-modules desktop)
(use-package-modules bootloaders emacs emacs-xyz wm terminals)

(define (keep-files filenames)
    (map (lambda (filename)
        (file-system
            (mount-point filename)
            (device (string-append "/keep" mount-point))
            (type "none")
            (check? #f)
            (flags '(no-atime bind-mount))))
        filenames))

(define os-device
    (file-system-label "$TARGET_OS_DEVICE_LABEL"))

(operating-system
    (kernel linux)
    (initrd microcode-initrd)
    (firmware (list linux-firmware))
    $CONFIG_INITRD

  (host-name "$TARGET_HOST_NAME")
  (timezone "Europe/Belgrade")
  (locale "en_SI.utf8")
  $CONFIG_BOOTLOADER
  $CONFIG_MAPPED_DEVICES

  (file-systems (append
      (list (file-system
                (device "none")
                (mount-point "/")
                (type "tmpfs")
                (check? #f)
                (needed-for-boot? #t)
                (options "mode=0755"))
            (file-system
          		(device "none")
          		(mount-point "/run")
          		(type "tmpfs")
          		(check? #f)
          		(needed-for-boot? #t)
          		(flags '(no-dev))
          		(options "mode=0755"))
            (file-system
        		(device "none")
        		(mount-point "/var/run")
        		(type "tmpfs")
        		(check? #f)
        		(needed-for-boot? #t)
        		(flags '(no-dev))
        		(options "mode=0755"))
            (file-system
    			(device "none")
    			(mount-point "/tmp")
    			(type "tmpfs")
    			(check? #f)
    			(needed-for-boot? #f))
            (file-system
    			(device os-device)
    			(mount-point "/boot")
    			(type "btrfs")
    			(check? #f)
    			(needed-for-boot? #t)
    			(flags '(no-atime))
    			(options (format #f "subvol=@boot"))
    			$CONFIG_FS_DEPENDENCIES)
            (file-system
    			(device os-device)
    			(mount-point "/gnu/store")
    			(type "btrfs")
    			(needed-for-boot? #t)
    			(flags '(read-only no-atime))
    			(options (format #f "subvol=@store,~
                                        compress=zstd:1"))
    			$CONFIG_FS_DEPENDENCIES)
            (file-system
    			(device os-device)
    			(mount-point "/var/guix")
    			(type "btrfs")
    			(needed-for-boot? #t)
    			(flags '(no-atime))
    			(options (format #f "subvol=@guix,~
                                        compress=zstd:1"))
                $CONFIG_FS_DEPENDENCIES)
            (file-system
    			(device os-device)
    			(mount-point "/var/lib")
    			(type "btrfs")
    			(needed-for-boot? #t)
    			(flags '(no-atime))
    			(options (format #f "subvol=@lib,~
                                        compress=zstd:1"))
    			$CONFIG_FS_DEPENDENCIES)
            (file-system
    			(device os-device)
    			(mount-point "/var/log")
    			(type "btrfs")
    			(check? #f)
    			(needed-for-boot? #t)
    			(flags '(no-atime))
    			(options (format #f "subvol=@log,~
                                        compress=zstd:1"))
    			$CONFIG_FS_DEPENDENCIES)
            (file-system
    			(device os-device)
    			(mount-point "/root")
    			(type "btrfs")
    			(flags '(no-atime))
    			(options (format #f "subvol=@root"))
    			$CONFIG_FS_DEPENDENCIES)
            (file-system
    			(device os-device)
    			(mount-point "/home")
    			(type "btrfs")
    			(flags '(no-atime))
    			(options (format #f "subvol=@home"))
    			$CONFIG_FS_DEPENDENCIES)
            (file-system
    			(device os-device)
    			(mount-point "/keep")
    			(type "btrfs")
    			(needed-for-boot? #t)
    			(flags '(no-atime))
    			(options (format #f "subvol=@keep"))
    			$CONFIG_FS_DEPENDENCIES)
            (file-system
    			(device os-device)
    			(mount-point "/swap")
    			(type "btrfs")
    			(flags '(no-atime))
    			(options (format #f "subvol=@swap,~
                                        nodatacow,~
                                        nodatasum"))
    			$CONFIG_FS_DEPENDENCIES)
            (file-system
    			(device os-device)
    			(mount-point "/snapshots")
    			(type "btrfs")
    			(check? #f)
    			(needed-for-boot? #t)
    			(flags '(no-atime))
    			(options (format #f "subvol=@snapshots,~
                                        compress=zstd:15"))
    			$CONFIG_FS_DEPENDENCIES)
            $CONFIG_FS_EFI
		 ;; Bind-mount persistent directories
		 (keep-files `("/etc/guix"))
		 %base-file-systems))

  ;; Define swap space
  (swap-devices
   (list
    (swap-space
     (target "/swap/swapfile")
     (dependencies
      (filter (file-system-mount-point-predicate "/swap")
	      file-systems)))))

  ;; Define users
  (users (cons (user-account
                (name "$TARGET_USER_NAME")
                (comment "$TARGET_USER_COMMENT")
                (group "users")
                (supplementary-groups '("wheel" "netdev"
                                        "audio" "video")))
               %base-user-accounts))

  ;; Add a bunch of window managers; we can choose one at
  ;; the log-in screen with F1.
  (packages (append (list
                     ;; window managers
                     sway
                     ;; text editors
                     emacs
                     ;; terminal emulators
                     foot)
                    %base-packages))

  ;; Use the "desktop" services, which include the X11
  ;; log-in service, networking with NetworkManager, and more.
  (services
   (modify-services %desktop-services
		    (guix-service-type config =>
				       (guix-configuration
					(inherit config)
					(substitute-urls
					 (append (list "https://substitutes.nonguix.org")
						 %default-substitute-urls))
					(authorized-keys
					 (append (list (plain-file "nonguix.pub"
								   "(public-key
                                                                     (ecc
                                                                      (curve Ed25519)
                                                                      (q #C1FD53E5D4CE971933EC50C9F307AE2171A2D3B52C804642A7A35F84F3A4EA98#)
                                                                      )
                                                                     )"))
						 %default-authorized-guix-keys))))))

  ;; Allow resolution of '.local' host names with mDNS.
  (name-service-switch %mdns-host-lookup-nss))
