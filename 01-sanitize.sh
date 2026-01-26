export GUIX_NVME=${GUIX_DRIVE%n1}

if ! command -v nvme >/dev/null 2>&1; then
    guix install nvme-cli
fi

nvme sanitize-log $GUIX_NVME

read -p "Do you want to sanitize device $GUIX_NVME? (y/n) " answer
if [[ $answer =~ ^[yY] ]]; then
	printf '%s\n' 'Starting sanitization process.' \
				  'You can follow the progress with: nvme sanitize-log $GUIX_NVME'
	nvme sanitize $GUIX_NVME -a start-block-erase
fi
