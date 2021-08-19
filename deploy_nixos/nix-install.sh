#! /usr/bin/env bash
set -euo pipefail

# Args
nix_user_chroot=$1
chroot_path=$2
shift 2


echo "downloading nix-user-chroot" >&2
curl -o "$nix_user_chroot" -sL https://github.com/nix-community/nix-user-chroot/releases/download/1.2.2/nix-user-chroot-bin-1.2.2-x86_64-unknown-linux-musl > /dev/null
chmod +x "$nix_user_chroot"
mkdir -m 0755 "$chroot_path"

echo "installing nix in chroot in $chroot_path" >&2
"$nix_user_chroot" "$chroot_path" bash -c 'curl -L https://nixos.org/nix/install | sh' > /dev/null

echo '{"nix-user-chroot":"'"$nix_user_chroot"'","chroot-path":"'"$chroot_path"'"}'
