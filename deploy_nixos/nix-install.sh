#! /usr/bin/env bash
set -euo pipefail

# Args
nix_portable=$1
NP_LOCATION="$(realpath "$2")"
shift 2

export NP_LOCATION


echo "downloading nix-portable" >&2
curl -o "$nix_portable" -sL https://github.com/DavHau/nix-portable/releases/download/v008/nix-portable > /dev/null
chmod +x "$nix_portable"

echo '{"nix-portable":"'"$nix_portable"'","np-location":"'"$NP_LOCATION"'"}'
