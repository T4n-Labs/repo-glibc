#!/usr/bin/env bash
# ============================================================
# T4n OS — AUTO BUILD & DEPLOY SCRIPT (repo-glibc)
# Lokasi : tools/auto.sh
# Fungsi : Setup Env, Auto Build (multi-arch), Auto Copy
# ============================================================

set -e # Berhenti jika ada error

# Deteksi direktori root repository (1 level di atas folder tools/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
VOID_PKGS_DIR="${REPO_DIR}/void-packages"

# Warna untuk output terminal
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
echo_success() { echo -e "${GREEN}[OK]${NC} $1"; }
echo_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
echo_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# ============================================================
# 1. SETUP ENVIRONMENT
# ============================================================
setup_env() {
    echo_info "Mengecek environment void-packages..."
    if [ ! -d "$VOID_PKGS_DIR" ]; then
        echo_warn "void-packages tidak ditemukan. Menyiapkan environment di $REPO_DIR..."
        echo_info "Cloning https://github.com/void-linux/void-packages..."
        git clone https://github.com/void-linux/void-packages "$VOID_PKGS_DIR"
        
        cd "$VOID_PKGS_DIR" || exit 1
        echo_info "Menjalankan 'xbps-src binary bootstrap' (Mungkin memakan waktu)..."
        ./xbps-src binary bootstrap
        cd "$REPO_DIR" || exit 1
        
        echo_success "Environment void-packages berhasil disiapkan!"
    else
        echo_success "void-packages sudah ada di $VOID_PKGS_DIR"
    fi
}

# ============================================================
# 2. AUTO BUILD
# ============================================================
build_pkg() {
    echo_info "=== AUTO BUILD PACKAGE ==="
    read -p "Masukkan nama package (pkgname): " PKGNAME
    
    if [ -z "$PKGNAME" ]; then
        echo_error "Nama package tidak boleh kosong!"
        exit 1
    fi

    TEMPLATE_FILE="$REPO_DIR/pkg-recipe/$PKGNAME/template"
    
    if [ ! -f "$TEMPLATE_FILE" ]; then
        echo_error "Template tidak ditemukan di: $TEMPLATE_FILE"
        exit 1
    fi

    echo_info "Template ditemukan. Mengecek syntax 'archs'..."
    
    # Parsing aman menggunakan sed untuk menghapus tanda kutip
    ARCHS_LINE=$(grep -E '^archs=' "$TEMPLATE_FILE" | head -n 1 | cut -d'=' -f2 | sed "s/[\"']//g" | tr -s ' ')
    
    if [ -z "$ARCHS_LINE" ]; then
        echo_warn "Baris 'archs' tidak ditemukan. Menggunakan default: x86_64"
        ARCHS_LINE="x86_64"
    else
        ARCHS_LINE=$(echo "$ARCHS_LINE" | tr ',' ' ')
    fi

    echo_success "Arsitektur yang akan di-build: $ARCHS_LINE"
    cd "$VOID_PKGS_DIR" || exit 1
    
    for arch in $ARCHS_LINE; do
        echo_info "Membangun $PKGNAME untuk arsitektur: $arch ..."
        if ./xbps-src -a "$arch" pkg "$PKGNAME"; then
            echo_success "Build berhasil untuk $arch!"
        else
            echo_error "Build GAGAL untuk $arch. Proses dihentikan."
            cd "$REPO_DIR" || exit 1
            exit 1
        fi
    done
    
    cd "$REPO_DIR" || exit 1
    echo_success "=== SEMUA BUILD SELESAI ==="
}

# ============================================================
# 3. AUTO COPY
# ============================================================
copy_pkgs() {
    echo_info "=== AUTO COPY PACKAGE ==="
    
    DEFAULT_SRC_PATH="$VOID_PKGS_DIR/hostdir/binpkgs"
    read -p "Masukkan PATH ke hostdir/binpkgs (Default: $DEFAULT_SRC_PATH): " SRC_PATH
    SRC_PATH="${SRC_PATH:-$DEFAULT_SRC_PATH}"

    # Ekspansi tilde (~) yang aman
    if [[ "$SRC_PATH" == "~"* ]]; then
        SRC_PATH="$HOME${SRC_PATH:1}"
    fi

    if [ ! -d "$SRC_PATH" ]; then
        echo_error "Direktori tidak ditemukan: $SRC_PATH"
        exit 1
    fi

    echo_info "Mencari file .xbps di $SRC_PATH ..."
    shopt -s nullglob
    XBPS_FILES=("$SRC_PATH"/*.xbps)
    shopt -u nullglob

    if [ ${#XBPS_FILES[@]} -eq 0 ]; then
        echo_error "Tidak ada file .xbps ditemukan di $SRC_PATH"
        exit 1
    fi

    COPIED_COUNT=0
    for file in "${XBPS_FILES[@]}"; do
        filename=$(basename "$file")
        base="${filename%.xbps}"
        arch="${base##*.}"
        
        if [[ "$arch" == "x86_64" || "$arch" == "i686" || "$arch" == "aarch64" || "$arch" == "armv6l" || "$arch" == "armv7l" ]]; then
            DEST_DIR="$REPO_DIR/$arch"
            mkdir -p "$DEST_DIR"
            
            echo_info "Menyalin: $filename -> $DEST_DIR/"
            cp "$file" "$DEST_DIR/"
            COPIED_COUNT=$((COPIED_COUNT + 1))
        else
            echo_warn "Arsitektur tidak dikenali untuk '$filename' ($arch). Dilewati."
        fi
    done
    
    echo_success "=== SELESAI: $COPIED_COUNT file berhasil disalin ke folder arsitektur ==="
}

# ============================================================
# MAIN LOGIC (BAGIAN INI YANG HILANG DI FILE SEBELUMNYA)
# ============================================================
case "$1" in
    -b|--build)
        setup_env
        build_pkg
        echo_info "Tips: Jalankan './tools/auto.sh --copy' untuk memindahkan hasil build."
        ;;
    -c|--copy)
        copy_pkgs
        echo_info "Tips: Jangan lupa commit dan push perubahan ke GitHub."
        ;;
    -s|--setup)
        setup_env
        ;;
    *)
        echo -e "${BLUE}============================================================${NC}"
        echo -e "${BLUE}  T4n OS — Repository Automation Script (repo-glibc)${NC}"
        echo -e "${BLUE}============================================================${NC}"
        echo "Penggunaan: ./tools/auto.sh [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  -b, --build   Setup env, tanya nama package, dan build multi-arch"
        echo "  -c, --copy    Tanya path binary, lalu copy ke folder arch yang sesuai"
        echo "  -s, --setup   Hanya setup environment void-packages"
        echo ""
        echo "Contoh Alur Kerja:"
        echo "  1. ./tools/auto.sh --build"
        echo "  2. ./tools/auto.sh --copy"
        echo "  3. git add . && git commit -m 'Add pkg' && git push"
        echo -e "${BLUE}============================================================${NC}"
        exit 0
        ;;
esac
