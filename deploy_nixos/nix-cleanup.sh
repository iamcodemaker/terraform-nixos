#! /usr/bin/env bash
set -euo pipefail

NP_LOCATION="$(realpath "$1")"
drv_path="$2"
out_path="$3"
shift 3

export NP_LOCATOIN

while IFS= read -r -d '' link; do
    if readlink "$link" | grep ^/nix > /dev/null; then
        newlink=$(readlink "$link" | sed -e "s:/nix:$NP_LOCATION/.nix-portable:")
        if [ -w "$(dirname "$link")" ]; then
            ln -sf "$newlink" "$link"
        else
            chmod +w "$(dirname "$link")"
            ln -sf "$newlink" "$link"
            chmod -w "$(dirname "$link")"
        fi
    fi
done <   <(find "$NP_LOCATION/.nix-portable/" ./result -type l -print0)

#drv_path=${drv_path//\/nix/$NP_LOCATION\/.nix-portable}
#out_path=${out_path//\/nix/$NP_LOCATION\/.nix-portable}

echo "{\"drv_path\":\"$drv_path\",\"out_path\":\"$out_path\"}"
