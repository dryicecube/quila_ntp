#!/bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive

echo "========================================"
echo " Ubuntu Chrony NTP Server Setup"
echo "========================================"

echo ""
echo "[1] Updating package list..."

echo ""
echo "[2] Installing chrony..."
sudo apt-get install -y chrony

echo ""
echo "[3] Detecting interfaces..."

INTERFACES=$(ip -4 -o addr show | awk '!/ lo / {print $2 " " $4}')

if [ -z "$INTERFACES" ]; then
    echo "ERROR: No IPv4 interfaces found."
    exit 1
fi

echo ""
echo "Available interfaces:"
echo ""

COUNT=0

while read -r LINE; do
    IFACE=$(echo "$LINE" | awk '{print $1}')
    ADDR=$(echo "$LINE" | awk '{print $2}')

    echo "[$COUNT] $IFACE -> $ADDR"

    eval IFACE_$COUNT=$IFACE
    eval ADDR_$COUNT=$ADDR

    COUNT=$((COUNT+1))
done <<< "$INTERFACES"

echo ""
read -rp "Select interface number: " IDX

INTERFACE=$(eval echo \$IFACE_$IDX)
CIDR=$(eval echo \$ADDR_$IDX)

if [ -z "$INTERFACE" ]; then
    echo "ERROR: Invalid selection."
    exit 1
fi

IP_ADDR=$(echo "$CIDR" | cut -d/ -f1)

SUBNET=$(echo "$IP_ADDR" | awk -F. \
'{print $1"."$2"."$3".0/24"}')

echo ""
echo "Selected interface : $INTERFACE"
echo "Selected IP        : $IP_ADDR"
echo "Selected subnet    : $SUBNET"

echo ""
echo "[4] Backing up chrony configuration..."

sudo cp -a /etc/chrony/chrony.conf \
/etc/chrony/chrony.conf.$(date +%F-%H%M%S).bak

echo ""
echo "[5] Writing chrony configuration..."

sudo tee /etc/chrony/chrony.conf > /dev/null <<EOF
pool ntp.ubuntu.com iburst

driftfile /var/lib/chrony/chrony.drift
makestep 1 3
rtcsync

allow $SUBNET
local stratum 10
bindaddress $IP_ADDR
EOF

echo ""
echo "[6] Restarting chrony..."

sudo systemctl restart chrony
sudo systemctl enable chrony

echo ""
echo "[7] Verifying chrony service..."

sudo systemctl --no-pager --full status chrony

echo ""
echo "[8] Checking NTP listening port..."

ss -ulpn | grep :123 || true

echo ""
echo "[9] Chrony tracking..."

chronyc tracking || true

echo ""
echo "========================================"
echo " NTP SERVER SETUP COMPLETE"
echo "========================================"

echo ""
echo "Server IP : $IP_ADDR"
echo "Subnet    : $SUBNET"
echo ""
echo "Use this server IP on KR260:"
echo "$IP_ADDR"


