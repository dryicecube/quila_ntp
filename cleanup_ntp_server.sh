#!/bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive

usage() {
    echo "Usage: $0 [--yes|-y]"
    exit 1
}

ASSUME_YES=false

while [ "$#" -gt 0 ]; do
    case "$1" in
        --yes|-y)
            ASSUME_YES=true
            shift
            ;;
        --help|-h)
            usage
            ;;
        *)
            echo "Unknown argument: $1"
            usage
            ;;
    esac
done

clean_server() {
    echo "========================================"
    echo " Ubuntu Chrony NTP Server CLEAN"
    echo "========================================"

    if [ "$ASSUME_YES" != "true" ]; then
        read -rp "This will stop/disable chrony, restore any backup and remove the package. Continue? [y/N] " CONF
        if [[ ! "$CONF" =~ ^[Yy] ]]; then
            echo "Aborting clean.";
            exit 0
        fi
    fi

    sudo systemctl stop chrony || true
    sudo systemctl disable chrony || true

    # Restore latest backup if available
    LATEST_BACKUP=$(ls -1t /etc/chrony/chrony.conf.*.bak 2>/dev/null | head -n1 || true)
    if [ -n "$LATEST_BACKUP" ]; then
        echo "Restoring backup: $LATEST_BACKUP"
        sudo cp -a "$LATEST_BACKUP" /etc/chrony/chrony.conf
    else
        echo "No chrony.conf backup found; removing /etc/chrony/chrony.conf if present"
        sudo rm -f /etc/chrony/chrony.conf || true
    fi

    echo "Removing chrony package..."
    sudo apt-get remove --purge -y chrony || true
    sudo apt-get autoremove -y || true

    echo "Removing drift file and data directory..."
    sudo rm -f /var/lib/chrony/chrony.drift || true
    sudo rm -rf /var/lib/chrony || true

    sudo systemctl daemon-reload || true

    echo "Service status (if present):"
    sudo systemctl --no-pager --full status chrony || true

    echo "Checking NTP listening port (should be absent):"
    ss -ulpn | grep :123 || true

    echo ""
    echo "========================================"
    echo " NTP SERVER CLEAN COMPLETE"
    echo "========================================"
}

clean_server
