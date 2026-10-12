#!/bin/bash
set -e

# Decode private key dari GitHub Secrets
echo "$SIGN_KEY" > private.pem
chmod 600 private.pem

# Sign semua file .xbps di setiap arsitektur
for arch in x86_64 i686 aarch64 armv6l armv7l; do
    if [ -d "$arch" ]; then
        echo "Signing packages for $arch..."
        
        # Hitung jumlah file .xbps di folder ini
        XBPS_COUNT=$(find "$arch" -maxdepth 1 -name "*.xbps" -type f | wc -l)
        
        if [ "$XBPS_COUNT" -eq 0 ]; then
            echo "  No .xbps files found in $arch/, skipping..."
            continue
        fi
        
        echo "  Found $XBPS_COUNT package(s) to sign"
        
        # Inisialisasi signature repository (sekali saja)
        # Buat repodata kosong jika belum ada
        if [ ! -f "$arch/repodata" ]; then
            echo "  Initializing repository metadata..."
            # Buat file repodata kosong dengan signing
            touch "$arch/.empty"
            xbps-rindex --privkey private.pem \
                --sign \
                --signedby "T4n OS Repository <t4nos.linux@gmail.com>" \
                "$arch" || true
            rm -f "$arch/.empty"
        fi
        
        # Sign semua paket .xbps yang belum ditandatangani
        for pkg in "$arch"/*.xbps; do
            if [ -f "$pkg" ]; then
                pkg_basename=$(basename "$pkg")
                # Cek apakah file .sig sudah ada
                if [ ! -f "${pkg}.sig" ]; then
                    echo "  Signing: $pkg_basename"
                    xbps-rindex --privkey private.pem \
                        --sign-pkg "$pkg"
                else
                    echo "  Already signed: $pkg_basename"
                fi
            fi
        done
        
        # Update repodata setelah semua paket ditandatangani
        echo "  Updating repository index..."
        xbps-rindex --privkey private.pem \
            --sign \
            --signedby "T4n OS Repository <admin@t4n.org>" \
            "$arch" || true
    fi
done

# Cleanup
rm -f private.pem

echo "✓ Signing completed"