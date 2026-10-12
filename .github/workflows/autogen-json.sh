#!/bin/bash
set -e

# Generate packages.json untuk setiap arsitektur
for arch in x86_64 i686 aarch64 armv6l armv7l; do
    if [ -d "$arch" ]; then
        echo "Generating packages.json for $arch..."
        
        # Mulai JSON array
        echo '{"packages": [' > "$arch/packages.json"
        
        first=true
        for pkg in "$arch"/*.xbps; do
            if [ -f "$pkg" ]; then
                filename=$(basename "$pkg")
                filesize=$(stat -f%z "$pkg" 2>/dev/null || stat -c%s "$pkg" 2>/dev/null || echo "0")
                
                # Parse nama paket: name-version.arch.xbps
                # Contoh: zvc-1.0_1.x86_64.xbps
                basename="${filename%.xbps}"  # zvc-1.0_1.x86_64
                pkgarch="${basename##*.}"      # x86_64
                rest="${basename%.*}"          # zvc-1.0_1
                version="${rest##*-}"          # 1.0_1
                name="${rest%-*}"              # zvc
                
                # Tambahkan koma untuk entri sebelumnya
                if [ "$first" = true ]; then
                    first=false
                else
                    echo "," >> "$arch/packages.json"
                fi
                
                # Tulis entri JSON
                cat >> "$arch/packages.json" << PKGJSON
    {
      "name": "$name",
      "version": "$version",
      "arch": "$arch",
      "filename": "$filename",
      "size": $filesize,
      "desc": "Package for $arch"
    }
PKGJSON
            fi
        done
        
        # Tutup JSON
        echo ']}' >> "$arch/packages.json"
        
        echo "  ✓ Created $arch/packages.json with $(grep -c '"name"' "$arch/packages.json") packages"
    fi
done

echo "✓ All packages.json generated"
