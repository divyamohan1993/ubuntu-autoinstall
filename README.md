# Ubuntu Autoinstall — Replicate This System

> **⚠️ DISCLAIMER:** Default credentials are `dmj:dmj` (intentionally public for quick setup).
> **CHANGE YOUR PASSWORD IMMEDIATELY** after installation: `sudo passwd dmj`

## What's included

| File | Purpose |
|------|---------|
| `autoinstall.yaml` | Ubuntu autoinstall config: partitions, locale, base packages. Fetches `post-install.sh` from GitHub automatically. |
| `post-install.sh` | First-boot script: repos, packages, sysctl optimizations |

## Partition layout (matches current system)

| Partition | Size | Filesystem | Mount |
|-----------|------|------------|-------|
| sda1 | 1 GB | FAT32 | /boot/efi |
| sda2 | 100 GB | ext4 | / |
| sda3 | 100 GB | NTFS | /mnt/experiments |
| sda4 | Remainder (~22.5 GB) | swap | [SWAP] |

## How to use

### Step 1: Prepare a Ventoy USB

1. **Install Ventoy** on a USB drive (https://www.ventoy.net)
2. **Download Ubuntu 24.04 Server ISO** and copy it to the USB root
3. **Copy `autoinstall.yaml`** to the USB root
4. **Create `ventoy/ventoy.json`** on the USB:

```
USB drive/
├── ventoy/
│   └── ventoy.json
├── ubuntu-24.04-live-server-amd64.iso
└── autoinstall.yaml          ← only this file needed on USB!
```

`ventoy/ventoy.json`:
```json
{
  "control": [
    {
      "VTOY_DEFAULT_SEARCH_ROOT": "/",
      "VTOY_DEFAULT_MENU_MODE": "0"
    }
  ],
  "auto_install": [
    {
      "image": "/ubuntu-24.04-live-server-amd64.iso",
      "template": "/autoinstall.yaml"
    }
  ]
}
```

### Step 2: Boot and walk away

1. Boot from USB
2. Select the Ubuntu ISO in Ventoy
3. The installer auto-detects `autoinstall.yaml` and runs **fully unattended**
4. It partitions the disk, installs the base OS, and on **late-commands** it fetches `post-install.sh` from GitHub:
   ```
   https://raw.githubusercontent.com/divyamohan1993/ubuntu-autoinstall/main/post-install.sh
   ```
5. After the installer reboots, `post-install.service` runs on first boot — installs everything (Docker, CUDA, MongoDB, R, Terraform, etc.) and applies all sysctl optimizations

### Step 3: Monitor progress (optional)

```bash
# Watch the first-boot script live:
journalctl -u post-install.service -f

# Or read the log file:
tail -f /var/log/post-install.log
```

### Step 4: Reboot and change password

```bash
sudo reboot          # For NVIDIA drivers, kernel updates
sudo passwd dmj      # CHANGE THE DEFAULT PASSWORD!
```

## How auto-fetch works

The `autoinstall.yaml` on the USB contains a `late-commands` section that runs:
```bash
curl -fsSL https://raw.githubusercontent.com/divyamohan1993/ubuntu-autoinstall/main/post-install.sh -o /root/post-install.sh
```
This means:
- **Only `autoinstall.yaml` is needed on the USB** — no other files
- `post-install.sh` is always fetched fresh from GitHub at install time
- Update `post-install.sh` on GitHub → every future install gets the latest version
- Requires **internet connection during installation** (the installer needs it anyway for packages)

## Alternative: Network boot (PXE/HTTP)

Boot the server ISO with kernel parameter:
```
autoinstall ds=nocloud-net;s=https://raw.githubusercontent.com/divyamohan1993/ubuntu-autoinstall/main/
```
(Requires `user-data` and `meta-data` files at that URL — see cloud-init docs)

## Customization

- **Different disk size?** Edit the partition sizes in `autoinstall.yaml` under `storage.config`
- **Different username?** Change `dmj` in both `autoinstall.yaml` and `post-install.sh`
- **Skip NVIDIA/CUDA?** Remove those lines from `post-install.sh`
- **Add more packages?** Add them to the `apt-get install` block in `post-install.sh`
- **Want the desktop GUI?** Add to `post-install.sh`:
  ```bash
  apt-get install -y ubuntu-desktop-minimal
  ```
