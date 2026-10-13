#!/bin/bash
# Index + tanda tangan repository, per arsitektur.
# Urutan WAJIB: xbps-rindex -a  ->  --sign  ->  --sign-pkg
#   -a        membuat <arch>-repodata (tanpa ini, --sign gagal:
#             "cannot read repository data: No such file or directory")
#   --sign    menandatangani repodata (membuat <arch>-repodata.sig2)
#   --sign-pkg menandatangani tiap paket (membuat <paket>.xbps.sig2)
# Tidak ada "|| true": kegagalan sebenarnya harus menggagalkan job.
set -euo pipefail

: "${SIGN_KEY:?SIGN_KEY belum diset (Settings > Secrets and variables > Actions)}"
SIGNEDBY="${SIGNEDBY:-T4n OS Repository <t4nos.linux@gmail.com>}"

# kunci disimpan di luar workspace dan SELALU dihapus saat keluar
KEY="$(mktemp)"
trap 'rm -f "$KEY"' EXIT
printf '%s\n' "$SIGN_KEY" > "$KEY"
chmod 600 "$KEY"

for arch in x86_64 i686 aarch64 armv6l armv7l; do
    [ -d "$arch" ] || continue

    # path ABSOLUT (xbps-rindex mengharapkan path absolut)
    mapfile -t pkgs < <(find "$PWD/$arch" -maxdepth 1 -type f -name '*.xbps' | sort)
    if [ "${#pkgs[@]}" -eq 0 ]; then
        echo "==> $arch: tidak ada .xbps, dilewati"
        continue
    fi
    echo "==> $arch: ${#pkgs[@]} paket"

    # paket arsitektur lain diproses di runner x86_64:
    # XBPS_ARCH memberi tahu xbps-rindex arsitektur target
    export XBPS_ARCH="$arch"

    echo "  [1/3] index"
    xbps-rindex -a "${pkgs[@]}"

    echo "  [2/3] tanda tangan repodata"
    xbps-rindex --privkey "$KEY" --sign --signedby "$SIGNEDBY" "$PWD/$arch"

    echo "  [3/3] tanda tangan paket"
    xbps-rindex --privkey "$KEY" --sign-pkg "${pkgs[@]}"

    # pastikan hasilnya ada
    [ -f "$arch/$arch-repodata" ]      || { echo "ERROR: $arch-repodata tidak terbentuk"; exit 1; }
    [ -f "$arch/$arch-repodata.sig2" ] || { echo "ERROR: $arch-repodata.sig2 tidak terbentuk"; exit 1; }
done

echo "✓ Signing completed"
