#! /usr/bin/env bash
set -euo pipefail

# Args
nix_user_chroot=$1
chroot_path=$2
shift 2


"$nix_user_chroot" "$chroot_path" find "/nix" -type -l -delete

echo '{}'
