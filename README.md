# Emerald IMEI / NVRAM partition backup

## Device

| | |
|---|---|
| Model | Redmi Note 13 Pro 4G — `23117RA68G` |
| Codename | `emerald` (emerald_eea) |
| SoC | MediaTek Helio G99 — `MT6789` |
| Android | 15 / HyperOS (`OS2.0.210.0.VNFEUXM`) |
| Fingerprint | `Redmi/emerald_eea/emerald:15/AP3A.240905.015.A2/OS2.0.210.0.VNFEUXM:user/release-keys` |
| Backup date | 2026-11-17 |

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




## Decrypt

- Arch/Manjaro: `sudo pacman -S gnupg zstd`
- Termux: `pkg install gnupg zstd`

`./decrypt.sh`

```bash
gpg -d nvram.img.zst.gpg | zstd -d > nvram.img
```
## Restoring (recovery)

First get verified images back:

```bash
./decrypt.sh        # prompts for passphrase -> restored/*.img, checks hashes
```

Then flash them back. **Only flash a partition that is actually corrupt**, and
double-check the partition name — writing the wrong image can hard-brick the phone.

**Method A - root:**
```bash
adb push restored/nvram.img /data/local/tmp/
adb shell su -c "dd if=/data/local/tmp/nvram.img of=/dev/block/by-name/nvram bs=1048576"
adb shell su -c "rm /data/local/tmp/nvram.img"
```

**Method B -BROM (brick boot):**
Use [mtkclient](https://github.com/bkerler/mtkclient) with the phone powered off
and connected in BROM mode:
```bash
python mtk w nvram restored/nvram.img
```

