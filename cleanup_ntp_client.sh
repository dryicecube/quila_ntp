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

clean_client() {
    echo "========================================"
    echo " KR260 NTP Client CLEAN"
    echo "========================================"

    if [ "$ASSUME_YES" != "true" ]; then
        read -rp "This will restore timesyncd.conf from the latest backup (if any), restart timesyncd and disable the wait-sync service. Continue? [y/N] " CONF
        if [[ ! "$CONF" =~ ^[Yy] ]]; then
            echo "Aborting clean.";
            exit 0
        fi
    fi

    # Restore latest backup if available
    LATEST_BACKUP=$(ls -1t /etc/systemd/timesyncd.conf.*.bak 2>/dev/null | head -n1 || true)
    if [ -n "$LATEST_BACKUP" ]; then
        echo "Restoring backup: $LATEST_BACKUP"
        sudo cp -a "$LATEST_BACKUP" /etc/systemd/timesyncd.conf
    else
        echo "No timesyncd.conf backup found; removing /etc/systemd/timesyncd.conf to allow defaults"
        sudo rm -f /etc/systemd/timesyncd.conf || true
    fi

    echo "Restarting systemd-timesyncd..."
    sudo systemctl restart systemd-timesyncd || true

    echo "Disabling systemd-time-wait-sync.service..."
    sudo systemctl disable systemd-time-wait-sync.service || true

    echo "Current time status:"
    timedatectl status || true

    echo "Current sync status:"
    timedatectl timesync-status || true

    echo "Current date:"
    date

    echo ""
    echo "========================================"
    echo " KR260 CLIENT CLEAN COMPLETE"
    echo "========================================"
}

clean_client
