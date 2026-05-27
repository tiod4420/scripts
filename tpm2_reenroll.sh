#!/usr/bin/env bash

set -Eeuo pipefail

DISK=${1:-/dev/nvme0n1p2}

# Wipe existing keys
systemd-cryptenroll --wipe-slot=tpm2 ${DISK}

# Enroll new keys
# PCR0: platform-code (UEFI firmware), not used as SecureBoot should verify it
# PCR4: boot-loader-code (UKI binary), not used as SecureBoot should verify it
# PCR7: secure-boot-policy (PK/KEK/DB/DBX)
# --tpm2-public-key not needed as key is in default path
systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 ${DISK}
