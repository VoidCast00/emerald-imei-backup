# Emerald IMEI / NVRAM partition backup

Off-device backup of the identity & calibration partitions for my phone, in case a
bad OTA, failed flash, or keybox/attestation tinkering ever corrupts them. This
device has **no custom recovery (TWRP) and no custom ROM**, so this repo is the
only safety net against a permanent loss of IMEI / cellular / sensors.

## Device

| | |
|---|---|
| Model | Redmi Note 13 Pro 4G — `23117RA68G` |
| Codename | `emerald` (emerald_eea) |
| SoC | MediaTek Helio G99 — `MT6789` |
| Android | 15 / HyperOS (`OS2.0.210.0.VNFEUXM`) |
| Fingerprint | `Redmi/emerald_eea/emerald:15/AP3A.240905.015.A2/OS2.0.210.0.VNFEUXM:user/release-keys` |
| Backup date | 2026-11-17 |

## ⚠️ Security

These partitions contain, in plaintext, your **IMEI, DRM/attestation keys and
sensor calibration**. They must **never** be committed raw.

- `raw/` and `restored/` are git-ignored. Only the **encrypted** `vault/*.img.zst.gpg`
  blobs are committed (AES-256, gpg symmetric).
- Keep the passphrase somewhere separate from this repo (a password manager).
  If you lose the passphrase, the backup is useless. If someone gets both the repo
  **and** the passphrase, they have your IMEI — so keep the repo **private**.

## What is backed up

| Partition | Size | Holds |
|---|---|---|
| `nvram` | 64 MB | Modem calibration, **IMEI**, Wi-Fi/BT MACs |
| `nvdata` | 64 MB | Modem NV data, network settings |
| `nvcfg` | 32 MB | NV config |
| `proinfo` | 3 MB | Product info / serial |
| `protect1` | 8 MB | Protected data (keys, calibration) |
| `protect2` | 8 MB | Protected data (keys, calibration) |
| `persist` | 48 MB | Sensor calibration, DRM (Widevine), per-device data |
| `persistbak` | 48 MB | Backup copy of persist |

Integrity hashes of the original dumps are in `SHA256SUMS.raw.txt` (safe to commit —
hashes reveal nothing) and are checked automatically by `decrypt.sh`.

## How this backup was made

Streamed each partition straight to the PC over ADB as root (nothing left on the phone):

```bash
for p in nvram nvdata nvcfg proinfo protect1 protect2 persist persistbak; do
  adb exec-out su -c "dd if=/dev/block/by-name/$p" > raw/$p.img
done
sha256sum raw/*.img > SHA256SUMS.raw.txt
```

## Committing it (encrypted)

```bash
./encrypt.sh        # prompts for a passphrase -> writes vault/*.img.zst.gpg
git add vault SHA256SUMS.raw.txt
git commit -m "emerald nvram/imei backup 2026-11-17"
git push            # to your PRIVATE GitHub repo
```

## Decrypt on ANY computer (not just the one that made this)

Nothing here is tied to a specific machine. The blobs are standard **gpg (AES-256)**
over **zstd**. To recover from anywhere you need only: this repo, the two tools, and
the passphrase.

Install the tools:
- Arch/Manjaro: `sudo pacman -S gnupg zstd`
- Debian/Ubuntu: `sudo apt install gnupg zstd`
- macOS: `brew install gnupg zstd`
- Windows: Gpg4win + zstd (via scoop/choco), or just use WSL
- On the phone itself (Termux): `pkg install gnupg zstd`

Then either run `./decrypt.sh`, or do it by hand (no scripts needed) — one command
per partition:

```bash
gpg -d nvram.img.zst.gpg | zstd -d > nvram.img
```

Repeat for each `*.img.zst.gpg`, then verify: `sha256sum -c SHA256SUMS.raw.txt`.

> The passphrase is the only thing that can't be recovered. Store it in a password
> manager that syncs off this PC (e.g. Bitwarden) so it's reachable from anywhere.
> If the phone still boots with root, you can even clone + decrypt + flash entirely
> from Termux with no PC at all.

## Restoring (recovery)

First get verified images back:

```bash
./decrypt.sh        # prompts for passphrase -> restored/*.img, checks hashes
```

Then flash them back. **Only flash a partition that is actually corrupt**, and
double-check the partition name — writing the wrong image can hard-brick the phone.

**Method A — booted, with root (quickest):**
```bash
adb push restored/nvram.img /data/local/tmp/
adb shell su -c "dd if=/data/local/tmp/nvram.img of=/dev/block/by-name/nvram bs=1048576"
adb shell su -c "rm /data/local/tmp/nvram.img"
# reboot afterwards
```

**Method B — offline via BROM (safest, works even on a dead boot):**
Use [mtkclient](https://github.com/bkerler/mtkclient) with the phone powered off
and connected in BROM mode:
```bash
python mtk w nvram restored/nvram.img
```
mtkclient talks to the chip's bootrom directly, so it works even if the phone
won't boot — the real reason a MediaTek backup like this is worth keeping.

> Note: on this phone the bootloader is unlocked. Restoring NVRAM/persist fixes
> IMEI/sensor loss; it does not relock the bootloader or change root state.
