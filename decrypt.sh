#!/usr/bin/env bash
# Decrypt + decompress vault/*.gpg back into restored/ and verify integrity
# against SHA256SUMS.raw.txt. Run this before any restore.
# Usage: ./decrypt.sh   (prompts for the passphrase)
set -euo pipefail
cd "$(dirname "$0")"
ls vault/*.img.zst.gpg >/dev/null 2>&1 || { echo "No vault/*.img.zst.gpg blobs found."; exit 1; }
mkdir -p restored

read -rsp "Decryption passphrase: " PASS; echo
for f in vault/*.img.zst.gpg; do
  n=$(basename "$f" .img.zst.gpg)
  printf 'decrypting %-12s ... ' "$n"
  gpg --batch --yes --quiet --passphrase-fd 3 -d "$f" 3<<<"$PASS" | zstd -d -q -c > "restored/$n.img"
  echo ok
done
unset PASS
echo
echo "Verifying checksums against the original dump ..."
( cd restored && sha256sum -c ../SHA256SUMS.raw.txt )
echo "All images verified. They are in restored/ — see README for how to flash them back."
