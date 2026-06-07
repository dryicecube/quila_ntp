# QuILA Local NTP Setup
 The objective of these scripts is to create a NTP server on ubuntu@Samgnya which is synced with the internet, and provides downstream time-sync to Kria boards

* Ubuntu PC uses Chrony
* Kria Boards use ```timesyncd``` (This is available in default built and doesn't need an internet connection for config.)
---

# Files

## `setup_ntp_server.sh`

Runs on the Ubuntu PC.

This script:

* installs and configures `chrony`
* detects available network interfaces
* lets the user select the Ethernet interface
* configures the selected interface as an NTP server
* enables Chrony at boot
* verifies NTP server operation

Chrony listens on:

* UDP port `123`

---

## `setup_ntp_client.sh`

Runs on the KR260 board.

This script:

* sets timezone to `Asia/Kolkata`
* configures `systemd-timesyncd`
* points the KR260 to the Ubuntu NTP server
* enables synchronization during boot
* verifies synchronization status

The KR260 communicates with the server over:

* UDP port `123`(base) 

## Ubuntu PC

```bash
sudo apt-get update
chmod +x setup_ntp_server.sh
./setup_ntp_server.sh
```

Select the Ethernet interface connected to the KR260.

---

## Cleanup scripts

Two helper scripts are included to undo the setup if needed. They remove the installed NTP-related configuration and packages, and restore any backups created by the setup scripts.

- `cleanup_ntp_server.sh`: Run on the Ubuntu PC to revert the `chrony` installation and restore backed-up configuration.
- `cleanup_ntp_client.sh`: Run on the KR260 to revert `systemd-timesyncd` changes and restore backed-up client settings.

Make both scripts executable before running:

```bash
chmod +x cleanup_ntp_server.sh
chmod +x cleanup_ntp_client.sh
./cleanup_ntp_server.sh   # on Ubuntu PC
./cleanup_ntp_client.sh   # on KR260
```

---

## KR260

```bash
chmod +x setup_ntp_client.sh

./setup_ntp_client.sh <SERVER_IP>
```

Example:

```bash
./setup_ntp_client.sh 192.168.15.100
```

---

# Verification

## On KR260

```bash
timedatectl status
```

Expected:

```text
System clock synchronized: yes
```

---

## On Ubuntu PC

```bash
chronyc clients
```

Shows connected KR260 clients.

---
