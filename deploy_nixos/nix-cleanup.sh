#! /usr/bin/env bash
set -euo pipefail

# Args
nix_user_chroot=$1
chroot_path=$2
shift 2

find . -type l 1>&2

#sudo rm -rf "$nix_user_chroot" "$chroot_path"

echo '{}'
