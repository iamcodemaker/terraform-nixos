#! /usr/bin/env bash
set -euo pipefail

path_module="$1"
result_file="$2"
drv_path="$3"
out_path="$4"
shift 4

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


#cp "${drv_path//\/nix/$HOME\/.nix-portable}" "$path_module"/
#drv_path="$path_module/$(basename "$drv_path")"
drv_path=${drv_path//\/nix/$HOME\/.nix-portable}
out_path=${out_path//\/nix/$HOME\/.nix-portable}

#chmod -R +w "$HOME/.nix-portable"
#rm -rf "$HOME/.nix-portable"
#rm -f "$result_file"

#find . -type l 1>&2
#exit 1

echo "{\"drv_path\":\"$drv_path\",\"out_path\":\"$out_path\"}"
