#!/bin/bash
# packages.json per arsitektur. Selalu dibuat ulang.
#   name, version, arch, filename, size  <- nama + ukuran file .xbps
#   desc                                 <- short_desc di pkg-recipe/<name>/template
# "version" tanpa revisi ("1.0"); revisi tetap ada di "filename" ("zvc-1.0_1.x86_64.xbps").
set -euo pipefail

RECIPES="pkg-recipe"

# escape untuk string JSON
json_esc() {
    printf '%s' "$1" | tr '\t\r\n' '   ' | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

# short_desc dari template (kosong jika tidak ada, mis. subpackage)
desc_of() {
    local t="$RECIPES/$1/template"
    [ -f "$t" ] || return 0
    (
        set +eu
        unset short_desc
        . "$t" >/dev/null 2>&1
        printf '%s' "${short_desc:-}"
    )
}

for arch in x86_64 i686 aarch64 armv6l armv7l; do
    [ -d "$arch" ] || continue
    echo "Generating packages.json for $arch..."

    out="$arch/packages.json"
    first=true
    {
        printf '{\n  "packages": ['
        for pkg in "$arch"/*.xbps; do
            [ -f "$pkg" ] || continue

            filename=$(basename "$pkg")
            size=$(wc -c < "$pkg" | tr -d ' ')

            # zvc-1.0_1.x86_64.xbps
            base="${filename%.xbps}"      # zvc-1.0_1.x86_64
            pkgarch="${base##*.}"         # x86_64
            rest="${base%.*}"             # zvc-1.0_1
            verrev="${rest##*-}"          # 1.0_1
            name="${rest%-*}"             # zvc
            version="${verrev%%_*}"       # 1.0
            desc=$(desc_of "$name")

            if [ "$first" = true ]; then first=false; else printf ','; fi
            printf '\n    {\n      "name": "%s",\n      "version": "%s",\n      "arch": "%s",\n      "filename": "%s",\n      "size": %s,\n      "desc": "%s"\n    }' \
                "$(json_esc "$name")" "$(json_esc "$version")" "$(json_esc "$pkgarch")" \
                "$(json_esc "$filename")" "$size" "$(json_esc "$desc")"
        done
        printf '\n  ]\n}\n'
    } > "$out"

    echo "  ✓ $out ($(grep -c '"name"' "$out") paket)"
done

echo "✓ All packages.json generated"
