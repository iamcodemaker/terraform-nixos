#! /usr/bin/env bash
set -euo pipefail

# Args
nix_user_chroot=$1
chroot_path=$2
shift 2


echo "downloading nix-portable" >&2
curl -o "$nix_user_chroot" -sL https://github.com/DavHau/nix-portable/releases/download/v008/nix-portable > /dev/null
chmod +x "$nix_user_chroot"

echo '{"nix-user-chroot":"'"$nix_user_chroot"'","chroot-path":"'"$chroot_path"'"}'
