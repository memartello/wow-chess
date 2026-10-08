#!/usr/bin/env bash
set -euo pipefail

project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
addon_dir='/home/mmartello/Games/battlenet/drive_c/Program Files (x86)/World of Warcraft/_classic_beta_/Interface/AddOns'

if [[ ! -d "$addon_dir" ]]; then
    printf 'No existe la carpeta de AddOns: %s\n' "$addon_dir" >&2
    exit 1
fi

cp -a "$project_dir/WoWChess" "$addon_dir/"
test -f "$addon_dir/WoWChess/WoWChess_Camelot.toc"
printf 'WoW Chess instalado en: %s/WoWChess\n' "$addon_dir"
