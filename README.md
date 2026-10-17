# Raspberry Pi 5 Home Server

This repository contains the declarative NixOS configuration for a Raspberry Pi 5 home server.

The server currently provides:

* AdGuard Home
* Grafana
* Prometheus
* Syncthing
* Caddy reverse proxy
* Tailscale remote access
* Automatic encrypted Restic backups

The operating system is fully declarative; however, a small number of one-time bootstrap steps are required when provisioning a new machine.

---

# Repository Structure

```
hosts/
    pi5/
modules/
secrets/
assets/
```

* **hosts/pi5** contains the machine-specific configuration.
* **modules** contains reusable service modules.
* **secrets** contains encrypted SOPS secrets.
* **assets** contains static assets such as SSH public keys.

---

# Initial Installation

## 1. Flash the SD image

Build the SD image from the flake and write it to an SD card.

Boot the Raspberry Pi from the SD card.

---

## 2. Log in

Log in locally using the bootstrap credentials defined in the configuration.

---

## 3. Partition the SSD

Erase the existing contents and create:

```
EFI      FAT32
ROOT     ext4
```

Generate a new hardware configuration:

```bash
sudo nixos-generate-config --root /
```

Copy the generated UUIDs into `hardware-configuration.nix`.

---

## 4. Copy the repository

Clone or copy this repository onto the Pi.

The remainder of the installation is performed directly from the repository.

---

# One-Time Bootstrap

The following steps are **not** currently handled declaratively.

## Age key

Copy the host age identity to:

```
/etc/sops/age/keys.txt
```

This key is required to decrypt all SOPS-managed secrets.

Without it, secret generation will fail.

---

## SSH host keys

Ensure SSH host keys exist before the first rebuild.

These are generated automatically during installation.

---

## Tailscale authentication

Generate a reusable authentication key from the Tailscale admin console.

Store the key in:

```
secrets/tailscale.yaml
```

Rebuild.

The machine will automatically join the tailnet.

---

## Restic repository

Create the backup repository once on the backup server:

```bash
restic init
```

Store the repository password in:

```
secrets/restic.yaml
```

---

## Restic SSH key

Generate a dedicated SSH key on the Pi:

```bash
ssh-keygen -t ed25519 \
    -f /var/lib/restic/id_ed25519
```

Copy the public key into:

```
assets/keys/backup.pub
```

The workstation authorizes this key for the backup user.

---

## Backup server

The workstation must provide:

* a dedicated `backup` system user
* OpenSSH
* internal SFTP
* a Restic repository
* Tailscale connectivity

The backup repository currently lives at:

```
/mnt/Media/backups/pi5
```

---

# Services

## AdGuard Home

Available at:

```
https://adguard.home.arpa
```

---

## Grafana

Available at:

```
https://grafana.home.arpa
```

---

## Prometheus

Available at:

```
https://prometheus.home.arpa
```

---

## Syncthing

Available at:

```
https://syncthing.home.arpa
```

---

# DNS

DNS is provided by AdGuard Home.

Local hostnames under `home.arpa` resolve to the Pi.

External access is provided through Tailscale.

---

# Backups

Nightly backups run automatically at 03:00.

The following data are currently backed up:

* `/etc/sops/age`
* `/var/lib/AdGuardHome`
* `/var/lib/grafana`
* `/var/lib/tailscale`

Snapshots are encrypted before leaving the Pi.

Repository passwords are managed exclusively through SOPS.

---

# Recovery

To restore onto a new Pi:

1. Flash the SD image.
2. Copy the age key.
3. Copy this repository.
4. Rebuild.
5. Restore the latest Restic snapshot.
6. Reboot.

No service-specific configuration should need to be recreated manually.

---

# Future Improvements

* Fully declarative SSD partitioning during installation.
* Automatic bootstrap of the Restic SSH key.
* Automatic registration of the backup key on the workstation.
* Hardware monitoring.
* SMART monitoring.
* UPS support.
* Off-site encrypted backup replication.
* Automated restore testing.
