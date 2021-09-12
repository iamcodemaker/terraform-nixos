#! /usr/bin/env bash
set -euo pipefail

. ~/.nix-profile/etc/profile.d/nix.sh

sudo rm -rf /nix

echo '{}'
