#! /usr/bin/env bash
set -euo pipefail

drv_path="$1"
out_path="$2"
shift 2

while IFS= read -r -d '' link; do
    if readlink "$link" | grep ^/nix > /dev/null; then
        newlink=$(readlink "$link" | sed -e "s:/nix:$HOME/.nix-portable:")
        if [ -w "$(dirname "$link")" ]; then
            ln -sf "$newlink" "$link"
        else
            chmod +w "$(dirname "$link")"
            ln -sf "$newlink" "$link"
            chmod -w "$(dirname "$link")"
        fi
    fi
done <   <(find "$HOME/.nix-portable/" ./result -type l -print0)

drv_path=${drv_path//\/nix/$HOME\/.nix-portable}
out_path=${out_path//\/nix/$HOME\/.nix-portable}

echo "{\"drv_path\":\"$drv_path\",\"out_path\":\"$out_path\"}"
