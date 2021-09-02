#! /usr/bin/env bash
set -euo pipefail

# Args
nix_user_chroot=$1
chroot_path=$2
first="$3"
shift 3


find "$chroot_path" "${first/#/\! -name }" "${@#/-a \! -name }"  -delete

rm "$nix_user_chroot"

echo '{}'
