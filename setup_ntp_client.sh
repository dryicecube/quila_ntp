#!/bin/bash

set -e

if [ $# -ne 1 ]; then
	    echo "Usage:"
	        echo "./setup_kria_ntp_client.sh <NTP_SERVER_IP>"
		    exit 1
fi

NTP_SERVER=$1

echo "========================================"
echo " KR260 NTP Client Setup"
echo "========================================"

echo ""
echo "[1] Setting timezone to Asia/Kolkata..."

sudo timedatectl set-timezone Asia/Kolkata

echo ""
echo "[2] Backing up timesyncd config..."

sudo cp -a /etc/systemd/timesyncd.conf \
	/etc/systemd/timesyncd.conf.$(date +%F-%H%M%S).bak

echo ""
echo "[3] Configuring NTP server..."

sudo tee /etc/systemd/timesyncd.conf > /dev/null <<EOF
[Time]
NTP=$NTP_SERVER
FallbackNTP=
PollIntervalMinSec=32
PollIntervalMaxSec=2048
EOF

echo ""
echo "[4] Restarting timesyncd..."

sudo systemctl restart systemd-timesyncd

echo ""
echo "[5] Enabling sync wait service..."

sudo systemctl enable systemd-time-wait-sync.service

echo ""
echo "[6] Waiting for synchronization..."

sleep 5

echo ""
echo "[7] Current time status..."

timedatectl status

echo ""
echo "[8] Current sync status..."

timedatectl timesync-status || true

echo ""
echo "[9] Current date..."

date

echo ""
echo "========================================"
echo " KR260 CLIENT SETUP COMPLETE"
echo "========================================"

echo ""
echo "NTP Server: $NTP_SERVER"


