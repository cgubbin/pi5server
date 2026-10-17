# Bootstrap Guide

This document describes the complete process for provisioning a new Raspberry Pi 5 from bare hardware.

Once these steps are complete, all future configuration should be managed declaratively through this repository.

---

# Requirements

Hardware

* Raspberry Pi 5
* SD card
* NVMe SSD
* USB NVMe enclosure (optional, for initial partitioning)
* Ethernet connection

Software

* This repository
* SSH access to the Pi
* Access to SOPS age keys
* Access to the Tailscale admin console

---

# 1. Build and flash the SD image

Build the SD image from the flake and flash it to an SD card.

Boot the Pi.

---

# 2. Log in

Log in using the bootstrap credentials.

Verify SSH access.

---

# 3. Partition the SSD

Remove any existing partition table.

Create:

* EFI (FAT32)
* Root (ext4)

Format both partitions.

---

# 4. Install onto the SSD

Mount:

```text
/
/boot
```

Generate a hardware configuration:

```bash
sudo nixos-generate-config --root /
```

Copy the generated filesystem UUIDs into:

```text
hosts/pi5/hardware-configuration.nix
```

---

# 5. Copy the repository

Clone or copy this repository onto the Pi.

All further rebuilds are performed from the repository.

---

# 6. Install the SOPS age identity

Copy the host age key to:

```text
/etc/sops/age/keys.txt
```

Verify:

```bash
sudo ls /etc/sops/age
```

Rebuild once to verify that all secrets decrypt successfully.

---

# 7. Install the system onto the SSD

Run:

```bash
sudo nixos-rebuild switch --flake .#pi5
```

Verify the machine boots from the SSD.

Remove the SD card.

---

# 8. Configure Tailscale

Generate a reusable authentication key.

Store it in:

```text
secrets/tailscale.yaml
```

Rebuild.

Confirm:

```bash
tailscale status
tailscale ping <workstation>
```

---

# 9. Configure the backup server

On the workstation:

* Install Restic.
* Create the `backup` system user.
* Create the backup repository directory.
* Initialise the repository.
* Store the repository password in SOPS.
* Configure OpenSSH for SFTP access.
* Install the Pi backup public key.

---

# 10. Configure Restic on the Pi

Generate:

```text
/var/lib/restic/id_ed25519
```

Copy the public key into:

```text
assets/keys/backup.pub
```

Rebuild the workstation.

Verify:

```bash
sudo sftp kitsune-backup
```

Verify:

```bash
sudo restic \
    -r sftp:kitsune-backup:/mnt/Media/backups/pi5 \
    --password-file /run/secrets/restic/password \
    snapshots
```

Run the first backup:

```bash
sudo systemctl start restic-backups-pi5.service
```

Confirm a snapshot exists.

---

# 11. Verify services

Check:

* AdGuard Home
* Grafana
* Prometheus
* Syncthing
* Caddy
* Tailscale
* Restic timer

---

# Manual bootstrap items

These operations currently remain outside the declarative configuration.

* SSD partitioning and formatting.
* Copying the SOPS age identity.
* Creating the Restic repository.
* Generating the Restic SSH key.
* Installing the Restic public key on the workstation.
* Generating the initial Tailscale authentication key.

Everything else should be reproducible via `nixos-rebuild`.

---

# Disaster recovery

For a replacement Pi:

1. Flash the SD image.
2. Install the age key.
3. Copy this repository.
4. Rebuild.
5. Restore the latest Restic snapshot.
6. Reboot.

No service configuration should need to be recreated manually.
