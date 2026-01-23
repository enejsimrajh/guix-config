NVME=${DISK%n1}

if ! command -v nvme >/dev/null 2>&1; then
    guix install nvme-cli
fi

nvme sanitize-log $NVME
read -p "Do you want to sanitize device $NVME? (y/n) " answer
if [[ $answer =~ ^[yY] ]]; then
	printf '%s\n' 'Starting sanitization process.' \
				  'You can follow the progress with: nvme sanitize-log $NVME'
	nvme sanitize $NVME -a start-block-erase
fi
