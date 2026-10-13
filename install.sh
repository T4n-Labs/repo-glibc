#!/bin/sh
# ============================================================
# T4n OS — Repository Installer (repo-glibc, khusus glibc)
#
# Disarankan: unduh, baca, lalu jalankan
#   curl -sLO https://t4n-labs.github.io/repo-glibc/install.sh
#   sudo sh install.sh
#
# Atau langsung:
#   curl -sL https://t4n-labs.github.io/repo-glibc/install.sh | sudo sh
# ============================================================

set -eu

# --- Konfigurasi -------------------------------------------------
URL_SITE="https://repo.t4nlabs.web.id/"
REPO_NAME="repo-glibc"
REPO_URL="https://t4n-labs.github.io/repo-glibc"      # tanpa "/" di akhir
CONF_FILE="${CONF_FILE:-/etc/xbps.d/10-glibc.conf}"

# Fingerprint resmi kunci repository, PERSIS seperti yang ditampilkan XBPS
# saat sync pertama (jalankan `sudo xbps-install -S` sekali, lalu salin ke sini).
FINGERPRINT="<ISI-SETELAH-SYNC-PERTAMA>"

# --- Output ------------------------------------------------------
if [ -t 1 ]; then
    B='\033[0;34m'; G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; N='\033[0m'
else
    B=''; G=''; Y=''; R=''; N=''
fi
info() { printf "${B}[INFO]${N} %s\n" "$1"; }
ok()   { printf "${G}[OK]${N} %s\n" "$1"; }
warn() { printf "${Y}[WARN]${N} %s\n" "$1"; }
err()  { printf "${R}[ERROR]${N} %s\n" "$1" >&2; }

# --- 1. Root -----------------------------------------------------
if [ "$(id -u)" -ne 0 ]; then
    err "Skrip ini harus dijalankan sebagai root."
    echo "Gunakan: sudo sh install.sh"
    exit 1
fi

# --- 2. Harus Void Linux / T4n OS (ada xbps) ----------------------
if ! command -v xbps-install >/dev/null 2>&1 || ! command -v xbps-uhelper >/dev/null 2>&1; then
    err "xbps tidak ditemukan. Skrip ini hanya untuk Void Linux / T4n OS."
    exit 1
fi

echo "============================================================"
echo "  T4n OS — Repository Installer ($REPO_NAME)"
echo "============================================================"
echo ""

# --- 3. Arsitektur -----------------------------------------------
ARCH=$(xbps-uhelper arch)
info "Arsitektur sistem: $ARCH"
case "$ARCH" in
    x86_64|i686|aarch64|armv6l|armv7l)
        ok "Arsitektur $ARCH didukung."
        ;;
    *)
        err "Arsitektur $ARCH tidak didukung. Repository ini khusus glibc:"
        echo "  x86_64, i686, aarch64, armv6l, armv7l"
        exit 1
        ;;
esac

# --- 4. Konfigurasi repository -----------------------------------
info "[1/2] Menambahkan repository ke sistem..."
mkdir -p "$(dirname "$CONF_FILE")"
echo "repository=${REPO_URL}/${ARCH}" > "$CONF_FILE"
ok "Disimpan di $CONF_FILE  (repository=${REPO_URL}/${ARCH})"

# --- 5. Sinkronisasi + konfirmasi fingerprint --------------------
# Kunci publik sudah tertanam di metadata repository. XBPS menampilkan fingerprint-nya
# dan meminta konfirmasi sebelum mengimpor. Konfirmasi itu satu-satunya pengaman,
# jadi tidak boleh disembunyikan atau dijawab otomatis tanpa sengaja.
echo ""
info "[2/2] Menyinkronkan database paket..."
echo ""
if [ "$FINGERPRINT" = "<ISI-SETELAH-SYNC-PERTAMA>" ]; then
    warn "Fingerprint resmi belum dicantumkan di skrip ini."
    echo "  Bandingkan dengan yang tertulis di https://github.com/T4n-Labs/repo-glibc"
else
    echo "  Fingerprint resmi : $FINGERPRINT"
    echo "  Jawab 'yes' HANYA jika fingerprint yang ditampilkan XBPS persis sama."
fi
echo ""

if [ "${T4N_ASSUME_YES:-0}" = 1 ]; then
    warn "T4N_ASSUME_YES=1: kunci diimpor TANPA konfirmasi fingerprint."
    xbps-install -S -y || { err "Sinkronisasi gagal."; exit 1; }
elif ( : < /dev/tty ) 2>/dev/null; then
    # prompt dibaca dari terminal, bukan dari stdin (kalau dijalankan lewat "curl | sh",
    # stdin adalah isi skrip ini sendiri)
    xbps-install -S < /dev/tty || { err "Sinkronisasi gagal atau kunci tidak diimpor. Periksa pesan di atas."; exit 1; }
else
    err "Tidak ada terminal interaktif untuk konfirmasi fingerprint."
    echo "Jalankan skrip ini langsung dari terminal, atau set T4N_ASSUME_YES=1"
    echo "jika fingerprint sudah kamu verifikasi sendiri."
    exit 1
fi

echo ""
echo "============================================================"
ok "Repository T4n OS siap dipakai."
echo "============================================================"
echo ""
echo "Cari dan pasang paket:"
echo "  xbps-query -Rs <nama_paket>"
echo "  sudo xbps-install <nama_paket>"
echo ""
echo "Pencarian paket di web: ${URL_SITE}"
echo ""