#!/usr/bin/env bash
set -euo pipefail

project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
addon_dir=${1:-${WOW_ADDONS_DIR:-}}

if [[ -z "$addon_dir" ]]; then
    candidates=(
        "$HOME/Games/battlenet/drive_c/Program Files (x86)/World of Warcraft/_classic_beta_/Interface/AddOns"
        "$HOME/.wine/drive_c/Program Files (x86)/World of Warcraft/_classic_beta_/Interface/AddOns"
        "$HOME/.wine/drive_c/Program Files/World of Warcraft/_classic_beta_/Interface/AddOns"
    )
    matches=()
    for candidate in "${candidates[@]}"; do
        if [[ -d "$candidate" ]]; then matches+=("$candidate"); fi
    done
    if (( ${#matches[@]} == 1 )); then
        addon_dir=${matches[0]}
    else
        printf 'Indicá la carpeta Interface/AddOns de _classic_beta_:\n' >&2
        printf '  ./install.sh "/ruta/a/World of Warcraft/_classic_beta_/Interface/AddOns"\n' >&2
        if (( ${#matches[@]} > 1 )); then
            printf 'Se encontraron varias instalaciones posibles:\n' >&2
            printf '  %s\n' "${matches[@]}" >&2
        fi
        exit 1
    fi
fi

if [[ ! -d "$addon_dir" ]]; then
    printf 'No existe la carpeta de AddOns: %s\n' "$addon_dir" >&2
    exit 1
fi

cp -a "$project_dir/WoWChess" "$addon_dir/"
test -f "$addon_dir/WoWChess/WoWChess_Camelot.toc"
printf 'WoW Chess instalado en: %s/WoWChess\n' "$addon_dir"
