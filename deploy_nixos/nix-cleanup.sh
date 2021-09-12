#! /usr/bin/env bash
set -euo pipefail

# Args
nix_user_chroot=$1
chroot_path=$2
module_path=$3
shift 3

echo vars: "$@" 1>&2

for path in "$@"; do
    ls "$chroot_path" 1>&2
    ls "$path" 1>&2
    cp "$path" "$module_path/"
done

sudo rm -rf "$nix_user_chroot" "$chroot_path"

echo "{\"drv_path\":\"$1\", \"out_path\":\"$2\"}"
