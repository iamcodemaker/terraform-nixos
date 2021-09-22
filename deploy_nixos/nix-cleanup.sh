#! /usr/bin/env bash
set -euo pipefail

result_file="$1"
shift 1

#rm -rf $HOME/.nix-portable/store
rm -f "$result_file"

echo '{}'
