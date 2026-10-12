#!/bin/bash
set -e

echo "$SIGN_KEY" > private.pem
chmod 600 private.pem

for arch in x86_64 i686 aarch64 armv6l armv7l; do
    if [ -d "$arch" ]; then
        echo "Signing packages for $arch..."
        
        XBPS_COUNT=$(find "$arch" -maxdepth 1 -name "*.xbps" -type f | wc -l)
        
        if [ "$XBPS_COUNT" -eq 0 ]; then
            echo "  No .xbps files found, skipping..."
            continue
        fi
        
        echo "  Found $XBPS_COUNT package(s)"
        
        # Sign individual packages
        for pkg in "$arch"/*.xbps; do
            if [ -f "$pkg" ]; then
                echo "  Signing: $(basename $pkg)"
                xbps-rindex --privkey private.pem --sign-pkg "$pkg" || true
            fi
        done
        
        # Create/update repodata
        echo "  Creating repository metadata..."
        xbps-rindex --privkey private.pem \
            --sign \
            --signedby "T4n OS Repository <t4nos.linux@gmail.com>" \
            "$arch" || true
    fi
done

rm -f private.pem
echo "✓ Signing completed"