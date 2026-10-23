#!/usr/bin/env bash
# ============================================================
# T4n OS — AUTO BUILD & DEPLOY SCRIPT (repo-glibc ONLY)
# Lokasi : vtools/auto.sh
# Fungsi : Setup Env, Sync Template, Auto Build, Auto Copy + Cleanup
# ============================================================
set -e # Berhenti jika ada error

# Deteksi direktori root repository (1 level di atas folder vtools/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
VOID_PKGS_DIR="${REPO_DIR}/void-packages"

# HANYA 5 ARSITEKTUR GLIBC YANG DIDUKUNG
HOST_ARCH="$(uname -m)"
ALL_SUPPORTED_ARCHS="x86_64 armv6l armv7l aarch64 i686"

# Warna untuk output terminal
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
echo_success() { echo -e "${GREEN}[OK]${NC} $1"; }
echo_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
echo_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
echo_clean()   { echo -e "${CYAN}[CLEAN]${NC} $1"; }

# ============================================================
# HELPER: ARSITEKTUR
# ============================================================
is_supported_arch() {
    [[ " $ALL_SUPPORTED_ARCHS " == *" $1 "* ]]
}

# Usage : resolve_archs /path/ke/template
# Aturan: Hanya mengambil 5 arsitektur glibc. Mengabaikan musl atau arsitektur lain.
resolve_archs() {
    local template="$1" line token a result=""
    
    # Ambil nilai archs= (abaikan komentar & tanda kutip)
    line=$(grep -E '^[[:space:]]*archs=' "$template" | head -n 1 \
    | sed -E "s/^[^=]*=//; s/#.*\$//; s/[\"']//g" || true)
    line=$(echo "$line" | tr ',' ' ' | xargs || true)

    # Tidak ada archs -> support semua 5 arch glibc
    if [ -z "$line" ]; then
        echo "$ALL_SUPPORTED_ARCHS"
        return 0
    fi

    for token in $line; do
        # Hapus bintang (*) atau suffix -musl jika ada di template
        token="${token%\*}"
        token="${token%-musl}"
        
        if is_supported_arch "$token"; then
            # hindari duplikat
            [[ " $result " == *" $token "* ]] || result="$result $token"
        else
            echo_warn "Arsitektur '$token' dari template tidak didukung (Hanya: $ALL_SUPPORTED_ARCHS). Dilewati." >&2
        fi
    done
    echo "${result# }"
}

# ============================================================
# HELPER: EKSTRAKSI NAMA PACKAGE & CLEANUP
# ============================================================

# Ekstrak nama package dari base filename (tanpa versi dan arch)
# Contoh input: tpkg-1.1.0_1.x86_64  ->  tpkg
#               libfoo-bar-2.0_1.aarch64  ->  libfoo-bar
#               calamari-3.4.2_4.x86_64  ->  calamari
extract_pkg_name() {
    local base="$1"
    # 1. Hapus suffix arsitektur terlebih dahulu (contoh: .x86_64, .aarch64, .noarch)
    local without_arch="${base%.*}"
    # 2. Hapus bagian versi (dimulai dari -<digit> sampai akhir)
    echo "$without_arch" | sed -E 's/-[0-9][0-9._-]*$//'
}

# Hapus versi lama dari package yang sama di folder tujuan
# Parameter: dest_dir, pkg_name, current_filename, arch
cleanup_old_versions() {
    local dest_dir="$1"
    local pkg_name="$2"
    local current_file="$3"
    local arch="$4"
    
    local cleaned=0
    # Cari semua file dengan nama package yang sama di folder tujuan
    shopt -s nullglob
    local old_files=("$dest_dir"/${pkg_name}-*.${arch}.xbps)
    shopt -u nullglob
    
    for old_file in "${old_files[@]}"; do
        # Lewati file yang baru saja disalin
        if [ "$(basename "$old_file")" = "$current_file" ]; then
            continue
        fi
        
        if [ -f "$old_file" ]; then
            echo_clean "Menghapus versi lama: $(basename "$old_file")"
            rm -f "$old_file"
            # Hapus juga file signature jika ada
            [ -f "${old_file}.sig2" ] && rm -f "${old_file}.sig2"
            cleaned=$((cleaned + 1))
        fi
    done
    
    if [ $cleaned -gt 0 ]; then
        echo_info "Berhasil menghapus $cleaned versi lama dari $pkg_name di $arch/"
    fi
}

# ============================================================
# 1. SETUP ENVIRONMENT
# ============================================================
setup_env() {
    echo_info "Mengecek environment void-packages..."
    if [ ! -d "$VOID_PKGS_DIR/.git" ]; then
        echo_warn "void-packages tidak ditemukan. Menyiapkan environment di $REPO_DIR..."
        echo_info "Cloning https://github.com/void-linux/void-packages (shallow)..."
        git clone https://github.com/void-linux/void-packages "$VOID_PKGS_DIR"
    else
        echo_success "void-packages sudah ada di $VOID_PKGS_DIR"
    fi

    if [ ! -d "$VOID_PKGS_DIR/masterdir-$HOST_ARCH" ] && [ ! -d "$VOID_PKGS_DIR/masterdir" ]; then
        echo_info "Menjalankan 'xbps-src binary-bootstrap' (Mungkin memakan waktu)..."
        (cd "$VOID_PKGS_DIR" && ./xbps-src binary-bootstrap)
        echo_success "Bootstrap selesai!"
    else
        echo_success "Masterdir sudah di-bootstrap."
    fi
}

# ============================================================
# 2. SYNC TEMPLATE (Fitur Pengambilan dari pkg-recipe)
# ============================================================
sync_template() {
    echo_info "=== SINKRONISASI TEMPLATE ==="
    read -rp "Masukkan nama package (pkgname): " PKGNAME
    
    if [[ ! "$PKGNAME" =~ ^[A-Za-z0-9._+-]+$ ]]; then
        echo_error "Nama package kosong atau mengandung karakter tidak valid!"
        exit 1
    fi

    RECIPE_DIR="$REPO_DIR/pkg-recipe/$PKGNAME"
    if [ ! -d "$RECIPE_DIR" ]; then
        echo_error "Folder recipe tidak ditemukan di: $RECIPE_DIR"
        exit 1
    fi

    echo_info "Menyalin template dari pkg-recipe ke void-packages/srcpkgs..."
    rm -rf "$VOID_PKGS_DIR/srcpkgs/$PKGNAME"
    cp -a "$RECIPE_DIR" "$VOID_PKGS_DIR/srcpkgs/$PKGNAME"
    echo_success "Template $PKGNAME berhasil disinkronkan ke srcpkgs."
}

# ============================================================
# 3. AUTO BUILD (Menu Nomor, Default Host, No -A)
# ============================================================
build_pkg() {
    echo_info "=== AUTO BUILD PACKAGE ==="
    read -rp "Masukkan nama package (pkgname): " PKGNAME
    
    if [[ ! "$PKGNAME" =~ ^[A-Za-z0-9._+-]+$ ]]; then
        echo_error "Nama package kosong atau mengandung karakter tidak valid!"
        exit 1
    fi

    RECIPE_DIR="$REPO_DIR/pkg-recipe/$PKGNAME"
    if [ ! -f "$RECIPE_DIR/template" ]; then
        echo_error "Template tidak ditemukan di: $RECIPE_DIR/template"
        exit 1
    fi

    # Fitur pengambilan template ke srcpkgs
    echo_info "Menyinkronkan template ke srcpkgs/$PKGNAME ..."
    rm -rf "$VOID_PKGS_DIR/srcpkgs/$PKGNAME"
    cp -a "$RECIPE_DIR" "$VOID_PKGS_DIR/srcpkgs/$PKGNAME"

    # Evaluasi arsitektur yang didukung template
    AVAILABLE_ARCHS="$(resolve_archs "$RECIPE_DIR/template")"
    if [ -z "$AVAILABLE_ARCHS" ]; then
        echo_error "Tidak ada arsitektur valid dari 'archs' di template."
        exit 1
    fi
    echo_success "Arsitektur yang didukung template: $AVAILABLE_ARCHS"

    # Tentukan angka default berdasarkan host arch
    DEFAULT_NUM=1
    case "$HOST_ARCH" in
        x86_64)  DEFAULT_NUM=1 ;;
        armv6l)  DEFAULT_NUM=2 ;;
        armv7l)  DEFAULT_NUM=3 ;;
        aarch64) DEFAULT_NUM=4 ;;
        i686)    DEFAULT_NUM=5 ;;
        *)       DEFAULT_NUM=1 ;;
    esac

    echo "Pilih arsitektur target:"
    echo "  [1] x86_64"
    echo "  [2] armv6l"
    echo "  [3] armv7l"
    echo "  [4] aarch64"
    echo "  [5] i686"
    echo "  [6] all (semua yang didukung)"
    read -rp "Masukkan pilihan (pisahkan koma jika lebih dari satu) [default: $DEFAULT_NUM]: " CHOICE
    CHOICE="${CHOICE:-$DEFAULT_NUM}"

    TARGETS=""
    IFS=',' read -ra CHOICES <<< "$CHOICE"
    for c in "${CHOICES[@]}"; do
        c="${c// /}" # hapus spasi
        case "$c" in
            1) TARGETS="$TARGETS x86_64" ;;
            2) TARGETS="$TARGETS armv6l" ;;
            3) TARGETS="$TARGETS armv7l" ;;
            4) TARGETS="$TARGETS aarch64" ;;
            5) TARGETS="$TARGETS i686" ;;
            6|all) TARGETS="$AVAILABLE_ARCHS"; break ;;
            x86_64|armv6l|armv7l|aarch64|i686) TARGETS="$TARGETS $c" ;; # fallback jika ketik nama
            *) echo_warn "Pilihan '$c' tidak valid. Dilewati." ;;
        esac
    done
    TARGETS=$(echo "$TARGETS" | xargs) # normalisasi spasi
    
    if [ -z "$TARGETS" ]; then
        echo_error "Tidak ada arsitektur valid yang dipilih."
        exit 1
    fi

    cd "$VOID_PKGS_DIR" || exit 1

    for arch in $TARGETS; do
        if [[ " $AVAILABLE_ARCHS " != *" $arch "* ]]; then
            echo_warn "$arch tidak termasuk arsitektur yang didukung template. Dilewati."
            continue
        fi

        # Tentukan flag: gunakan -a jika cross-compile, kosongkan jika native
        # TIDAK MENGGUNAKAN -A
        if [ "$arch" = "$HOST_ARCH" ]; then
            ARCH_FLAG=()
        else
            ARCH_FLAG=(-a "$arch")
        fi

        echo_info "Membangun $PKGNAME untuk arsitektur: $arch ..."
        if ./xbps-src "${ARCH_FLAG[@]}" pkg "$PKGNAME"; then
            echo_success "Build berhasil untuk $arch!"
        else
            echo_error "Build GAGAL untuk $arch. Proses dihentikan."
            cd "$REPO_DIR" || true
            exit 1
        fi
    done

    cd "$REPO_DIR" || exit 1
    echo_success "=== BUILD SELESAI ==="
}

# ============================================================
# 4. AUTO COPY + CLEANUP VERSI LAMA
# ============================================================
copy_pkgs() {
    echo_info "=== AUTO COPY & CLEANUP PACKAGE ==="
    DEFAULT_SRC_PATH="$VOID_PKGS_DIR/hostdir/binpkgs"
    read -rp "Masukkan PATH ke hostdir/binpkgs (Default: $DEFAULT_SRC_PATH): " SRC_PATH
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
        base="${filename%.xbps}"       # contoh: tpkg-1.1.0_1.x86_64
        arch="${base##*.}"             # contoh: x86_64
        
        # Ekstrak nama package (tanpa versi dan arch)
        pkg_name="$(extract_pkg_name "$base")"

        # noarch -> salin ke 5 folder arsitektur glibc + cleanup
        if [[ "$arch" == "noarch" ]]; then
            for a in x86_64 armv6l armv7l aarch64 i686; do
                DEST_DIR="$REPO_DIR/$a"
                mkdir -p "$DEST_DIR"
                
                # Hapus versi lama sebelum menyalin
                cleanup_old_versions "$DEST_DIR" "$pkg_name" "$filename" "$a"
                
                echo_info "Menyalin (noarch): $filename -> $DEST_DIR/"
                cp "$file" "$DEST_DIR/"
                [ -f "$file.sig2" ] && cp "$file.sig2" "$DEST_DIR/"
            done
            COPIED_COUNT=$((COPIED_COUNT + 1))
            continue
        fi

        if is_supported_arch "$arch"; then
            DEST_DIR="$REPO_DIR/$arch"
            mkdir -p "$DEST_DIR"
            
            # Hapus versi lama sebelum menyalin
            cleanup_old_versions "$DEST_DIR" "$pkg_name" "$filename" "$arch"
            
            echo_info "Menyalin: $filename -> $DEST_DIR/"
            cp "$file" "$DEST_DIR/"
            [ -f "$file.sig2" ] && cp "$file.sig2" "$DEST_DIR/"
            COPIED_COUNT=$((COPIED_COUNT + 1))
        else
            echo_warn "Arsitektur tidak dikenali untuk '$filename' ($arch). Dilewati."
        fi
    done

    echo_success "=== SELESAI: $COPIED_COUNT file berhasil disalin, versi lama telah dibersihkan ==="
}

# ============================================================
# MAIN LOGIC
# ============================================================
case "$1" in
    -b|--build)
        setup_env
        build_pkg
        echo_info "Tips: Jalankan './vtools/auto.sh --copy' untuk memindahkan hasil build."
        ;;
    -c|--copy)
        copy_pkgs
        echo_info "Tips: Jangan lupa commit dan push perubahan ke GitHub."
        ;;
    -t|--sync)
        setup_env
        sync_template
        ;;
    -s|--setup)
        setup_env
        ;;
    *)
        echo -e "${BLUE}============================================================${NC}"
        echo -e "${BLUE}  T4n OS — Repository Automation Script (repo-glibc)${NC}"
        echo -e "${BLUE}============================================================${NC}"
        echo "Penggunaan: ./vtools/auto.sh [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  -b, --build   Setup env, sync template, menu pilihan arch, lalu build"
        echo "  -c, --copy    Tanya path binary, copy ke folder arch, & hapus versi lama"
        echo "  -t, --sync    Hanya sinkronisasi template dari pkg-recipe ke srcpkgs"
        echo "  -s, --setup   Hanya setup environment void-packages"
        echo ""
        echo "Arsitektur yang didukung: $ALL_SUPPORTED_ARCHS"
        echo -e "${BLUE}============================================================${NC}"
        exit 0
        ;;
esac