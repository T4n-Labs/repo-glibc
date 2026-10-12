#!/bin/sh
# ============================================================
# T4n OS — Repository Auto-Installer
# Usage: curl -sL https://t4n-labs.github.io/repo-glibc/install.sh | sudo sh
# ============================================================

set -e

# Konfigurasi
URL_SITE="https://repo.t4nlabs.web.id/"
REPO_NAME="repo-glibc"
REPO_URL="https://t4n-labs.github.io/repo-glibc/"
CONF_FILE="/etc/xbps.d/10-glibc.conf"
KEY_URL="${REPO_URL}keys/private.pem.pub"
KEY_DEST="/var/db/xbps/keys/t4n-glibc.pub"

# Warna output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo_info() { echo "${BLUE}[INFO]${NC} $1"; }
echo_success() { echo "${GREEN}[OK]${NC} $1"; }
echo_warn() { echo "${YELLOW}[WARN]${NC} $1"; }
echo_error() { echo "${RED}[ERROR]${NC} $1"; }

# 1. Cek Hak Akses Root
if [ "$(id -u)" -ne 0 ]; then
    echo_error "Script ini harus dijalankan sebagai root!"
    echo "Gunakan perintah: curl -sL ${REPO_URL}install.sh | sudo sh"
    exit 1
fi

echo "============================================================"
echo "  T4n OS — Repository Installer ($REPO_NAME)"
echo "============================================================"
echo ""

# 2. Deteksi Arsitektur Sistem
ARCH=$(xbps-uhelper arch 2>/dev/null || echo "x86_64")
echo_info "Mendeteksi arsitektur sistem: $ARCH"

# Validasi arsitektur yang didukung
case "$ARCH" in
    x86_64|i686|aarch64|armv6l|armv7l)
        echo_success "Arsitektur $ARCH didukung."
        ;;
    *)
        echo_warn "Arsitektur $ARCH tidak secara eksplisit terdaftar, namun akan tetap dicoba."
        ;;
esac

# 3. Buat Direktori Konfigurasi
echo_info "[1/4] Menyiapkan direktori konfigurasi..."
mkdir -p /etc/xbps.d

# 4. Tulis File Konfigurasi Repository
echo_info "[2/4] Menambahkan repository ke sistem..."
echo "repository=${REPO_URL}${ARCH}" > "$CONF_FILE"
echo_success "Konfigurasi disimpan di $CONF_FILE"

# 5. Unduh Kunci Publik (Opsional tapi sangat disarankan)
echo_info "[3/4] Mengunduh kunci publik untuk verifikasi tanda tangan..."
mkdir -p /var/db/xbps/keys

if curl -sLf "$KEY_URL" -o "$KEY_DEST" 2>/dev/null; then
    echo_success "Kunci publik berhasil diunduh ke $KEY_DEST"
else
    echo_warn "Gagal mengunduh kunci publik. Repository mungkin belum ditandatangani atau file kunci belum tersedia."
    echo_warn "Anda mungkin perlu menambahkan 'signedby=no' ke $CONF_FILE jika terjadi error saat sync."
fi

# 6. Sinkronisasi Database
echo_info "[4/4] Menyinkronkan database paket xbps..."
if xbps-install -S >/dev/null 2>&1; then
    echo_success "Sinkronisasi berhasil!"
else
    echo_error "Sinkronisasi gagal. Periksa koneksi internet atau konfigurasi repository."
    exit 1
fi

echo ""
echo "============================================================"
echo_success "Instalasi Repository T4n OS Berhasil!"
echo "============================================================"
echo ""
echo "Anda sekarang dapat mencari dan menginstal paket:"
echo "  🔍 xbps-query -Rs <nama_paket>"
echo "  📦 sudo xbps-install <nama_paket>"
echo ""
echo "Kunjungi mesin pencari paket kami di:"
echo "  🌐 ${URL_SITE}"
echo ""
