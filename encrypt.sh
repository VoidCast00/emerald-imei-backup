#!/usr/bin/env bash
# Compress + encrypt each raw partition image in raw/ into vault/ so it can be
# committed safely. Raw images themselves are git-ignored and never leave this PC.
# Usage: ./encrypt.sh   (prompts once for a passphrase)
set -euo pipefail
cd "$(dirname "$0")"
[ -d raw ] && ls raw/*.img >/dev/null 2>&1 || { echo "No raw/*.img images found."; exit 1; }
mkdir -p vault

read -rsp "Encryption passphrase: " PASS; echo
read -rsp "Confirm passphrase:    " PASS2; echo
[ "$PASS" = "$PASS2" ] || { echo "Passphrases do not match."; exit 1; }
[ -n "$PASS" ] || { echo "Empty passphrase refused."; exit 1; }

for f in raw/*.img; do
  n=$(basename "$f" .img)
  printf 'encrypting %-12s ... ' "$n"
  zstd -19 -q -c "$f" | gpg --batch --yes --symmetric --cipher-algo AES256 \
    --passphrase-fd 3 -o "vault/$n.img.zst.gpg" 3<<<"$PASS"
  echo "$(du -h "vault/$n.img.zst.gpg" | cut -f1)"
done
unset PASS PASS2
echo
echo "Done. Encrypted blobs are in vault/."
echo "Commit them with:  git add vault SHA256SUMS.raw.txt && git commit -m 'backup' && git push"
