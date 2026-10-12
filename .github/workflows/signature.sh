#!/bin/bash
set -e

echo "$SIGN_KEY" > private.pem
chmod 600 private.pem

# Sign semua file .xbps di setiap arsitektur
for arch in x86_64 i686 aarch64 armv6l armv7l; do
    if [ -d "$arch" ]; then
        echo "Signing packages for $arch..."
        
        # Inisialisasi signature repository (sekali saja)
        if [ ! -f "$arch/repodata" ]; then
            xbps-rindex --privkey private.pem \
                --sign \
                --signedby "T4n OS Repository <t4nos.linux@gmail.com>" \
                "$arch"
        fi
        
        # Sign semua paket .xbps
        for pkg in "$arch"/*.xbps; do
            if [ -f "$pkg" ]; then
                echo "  Signing: $(basename $pkg)"
                xbps-rindex --privkey private.pem \
                    --sign-pkg "$pkg"
            fi
        done
    fi
done

# Cleanup
rm -f private.pem

echo "✓ Signing completed"