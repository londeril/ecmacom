#!/bin/bash
# This script will unmount and eject the given RDX drive, or mount it.

usage() {
  cat <<EOF
Usage: $0 [--add|--remove] <device>

Examples:
  $0 --add /dev/sdX     # Mounts the RDX drive /dev/sdX to /mnt/rdx
  $0 --remove /dev/sdX  # Unmounts and ejects the RDX drive /dev/sdX

Arguments:
  --add       Mount the specified device to /mnt/rdx
  --remove    Unmount and eject the specified device
  <device>    The device file (e.g., /dev/sdX)

Note: Replace /dev/sdX with your RDX drive's device.
EOF
}

if [ "$#" -ne 2 ]; then
  echo "Error: Invalid arguments."
  usage
  exit 1
fi

ACTION="$1"
DRIVE="$2"

case "$ACTION" in
  --remove)
    if umount "$DRIVE"; then
      echo "Successfully unmounted $DRIVE."
    else
      echo "Failed to unmount $DRIVE"
      exit 2
    fi
    if eject "$DRIVE"; then
      echo "Successfully ejected $DRIVE."
    else
      echo "Failed to eject $DRIVE"
      exit 3
    fi
    ;;
  --add)
    if mount "$DRIVE" /mnt/rdx; then
      echo "Successfully mounted $DRIVE to /mnt/rdx."
    else
      echo "Failed to mount $DRIVE to /mnt/rdx"
      exit 4
    fi
    ;;
  -h|--help|--usage|*)
    usage
    ;;
esac
