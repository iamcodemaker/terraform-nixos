#! /usr/bin/env bash
set -euo pipefail

result_file="$1"
drv_path="$2"
out_path="$3"
shift 4

for link in $(find "$HOME/.nix-portable/" "$result_file" -type l); do
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
done

drv_path=${drv_path//\/nix/$HOME\/.nix-portable}
out_path=${out_path//\/nix/$HOME\/.nix-portable}

echo "{\"drv_path\":\"$drv_path\",\"out_path\":\"$out_path\"}"
