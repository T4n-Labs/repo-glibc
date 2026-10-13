#!/bin/bash
set -e

# Generate index.html untuk root
cat > index.html << 'INDEX'
<!DOCTYPE html>
<html>
<head>
    <title>Index of /</title>
    <style>
        body { font-family: monospace; background: #1e1e1e; color: #d4d4d4; padding: 20px; }
        a { color: #569cd6; text-decoration: none; }
        a:hover { text-decoration: underline; }
        h1 { color: #4ec9b0; }
    </style>
</head>
<body>
    <h1>Index of /</h1>
    <ul>
INDEX

# Tambahkan link untuk setiap arsitektur
for arch in x86_64 i686 aarch64 armv6l armv7l; do
    if [ -d "$arch" ]; then
        echo "    <li><a href=\"${arch}/\">${arch}/</a></li>" >> index.html
    fi
done

cat >> index.html << 'INDEX'
    </ul>
    <p>Source: <a href="https://github.com/T4n-Labs/repo-glibc">GitHub</a></p>
    <p>T4n Labs ◉ Gh0sT4n</p>
</body>
</html>
INDEX

# Generate index.html untuk setiap arsitektur
for arch in x86_64 i686 aarch64 armv6l armv7l; do
    if [ -d "$arch" ]; then
        cat > "$arch/index.html" << ARCHINDEX
<!DOCTYPE html>
<html>
<head>
    <title>Index of /${arch}/</title>
    <style>
        body { font-family: monospace; background: #1e1e1e; color: #d4d4d4; padding: 20px; }
        a { color: #569cd6; text-decoration: none; }
        a:hover { text-decoration: underline; }
        h1 { color: #4ec9b0; }
    </style>
</head>
<body>
    <h1>Index of /${arch}/</h1>
    <ul>
ARCHINDEX

        # List semua file (.xbps, .sig2, repodata, packages.json), kecuali index.html itu sendiri
        for file in "$arch"/*; do
            if [ -f "$file" ]; then
                filename=$(basename "$file")
                [ "$filename" = "index.html" ] && continue
                echo "        <li><a href=\"${filename}\">${filename}</a></li>" >> "$arch/index.html"
            fi
        done

        cat >> "$arch/index.html" << 'ARCHINDEX'
    </ul>
    <p>Source: <a href="https://github.com/T4n-Labs/repo-glibc">GitHub</a></p>
    <p>T4n Labs ◉ Gh0sT4n</p>
</body>
</html>
ARCHINDEX
    fi
done

echo "✓ index.html generated"
