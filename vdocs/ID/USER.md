# T4n OS Repository - Panduan Pengguna

Selamat datang di Repositori T4n OS. Repositori ini menyediakan paket biner (`.xbps`) yang dikompilasi, ditandatangani secara kriptografis, dan dipelihara secara resmi untuk sistem T4n OS dan Void Linux.

🔍 **Mesin Pencari Paket Web:** Jelajahi, filter, dan temukan semua paket yang tersedia dengan mudah di **[repo.t4nlabs.web.id/site/glibc.html](https://repo.t4nlabs.web.id/site/glibc.html)**.

##  Arsitektur yang Didukung
Repositori kami dibangun untuk mendukung berbagai arsitektur perangkat keras:
- **x86_64** (PC 64-bit Standar)
- **i686** (PC 32-bit)
- **aarch64** (ARM 64-bit)
- **armv6l** & **armv7l** (ARM 32-bit / Raspberry Pi)

## 1. Menambahkan Repositori

Anda dapat menambahkan repositori menggunakan penginstal otomatis kami (Direkomendasikan) atau secara manual.

### Opsi A: Penginstal Otomatis (Direkomendasikan)
Cukup jalankan perintah satu baris ini di terminal Anda. Perintah ini akan secara otomatis mendeteksi arsitektur Anda, menambahkan repositori, dan mengimpor kunci tanda tangan publik:

```bash
curl -sL https://t4n-labs.github.io/repo-glibc/install.sh | sudo sh
```

### Opsi B: Pengaturan Manual
**Langkah 1: Buat direktori konfigurasi (jika belum ada)**
```bash
sudo mkdir -p /etc/xbps.d
```

**Langkah 2: Tambahkan konfigurasi repositori**
Pilih perintah yang sesuai dengan arsitektur sistem Anda:

```bash
# Untuk x86_64 (PC 64-bit Standar)
echo 'repository=https://t4n-labs.github.io/repo-glibc/x86_64' | sudo tee /etc/xbps.d/10-glibc.conf

# Untuk i686 (PC 32-bit)
echo 'repository=https://t4n-labs.github.io/repo-glibc/i686' | sudo tee /etc/xbps.d/10-glibc.conf

# Untuk aarch64 (ARM 64-bit)
echo 'repository=https://t4n-labs.github.io/repo-glibc/aarch64' | sudo tee /etc/xbps.d/10-glibc.conf
```
*(Catatan: Kami juga memelihara `repo-musl`, `repo-server`, dan `repo-security`. Sesuaikan URL dan nama file `.conf` jika Anda menggunakan repositori tersebut.)*

**Langkah 3: Sinkronisasi database paket**
Perbarui indeks paket lokal Anda untuk mengenali repositori baru:
```bash
sudo xbps-install -S
```

## 2. Mencari dan Menginstal Paket

### Mencari Paket
Anda dapat mencari paket yang tersedia di repositori T4n OS menggunakan terminal:
```bash
xbps-query -Rs "nama_paket"
```
*Contoh: `xbps-query -Rs "zvc"`*

Sebagai alternatif, gunakan **Mesin Pencari Paket Web** kami (lihat bagian 3 di bawah) untuk antarmuka grafis.

### Menginstal Paket
Setelah menemukan paket yang Anda inginkan, instal menggunakan:
```bash
sudo xbps-install nama_paket
```

## 3. Menggunakan Mesin Pencari Paket Web

Kami menyediakan antarmuka web yang cepat dan ringan untuk menjelajahi dan mencari semua paket yang tersedia di **[repo.t4nlabs.web.id/site/glibc.html](https://repo.t4nlabs.web.id/site/glibc.html)**.

**Fitur Utama:**
- **Pencarian Langsung (Live Search):** Memfilter paket secara instan saat Anda mengetik (dengan *debounce* 110ms untuk performa yang mulus).
- **Tab Arsitektur:** Filter paket berdasarkan arsitektur (`x86_64`, `aarch64`, dll.) dengan penghitung langsung yang menunjukkan berapa banyak paket yang tersedia untuk masing-masing arsitektur.
- **Paginasi:** Navigasi `[1] [2] [3] ... [Terakhir]` yang rapi untuk kumpulan data besar.
- **URL yang Dapat Dibagikan:** Status pencarian disimpan di hash URL (misalnya, `#q=vim&arch=x86_64&page=2`), memungkinkan Anda menandai atau membagikan pencarian tertentu.
- **Pintasan Keyboard:** 
  - Tekan `/` untuk langsung memfokuskan kursor ke bilah pencarian.
  - Tekan `Esc` untuk menghapus kueri pencarian.
- **Salin Satu Klik:** Klik tombol `xbps-install ⧉` di sebelah paket mana pun untuk menyalin perintah instalasi langsung ke clipboard Anda.

## 4. Menghapus Repositori

Jika Anda tidak lagi ingin menggunakan repositori T4n OS, cukup hapus file konfigurasi dan sinkronisasi ulang:

```bash
sudo rm /etc/xbps.d/10-glibc.conf
sudo xbps-install -S
```

## ❓ Troubleshooting & FAQ

**T: Saya mendapatkan error: `repository is not signed, refusing to continue!`**
**J:** Repositori T4n OS ditandatangani secara kriptografis. Jika Anda menggunakan penginstal otomatis (`curl ... | sudo sh`), kunci publik seharusnya sudah diimpor. Jika Anda mengaturnya secara manual, pastikan file konfigurasi Anda diformat dengan benar. Anda dapat memaksa sinkronisasi ulang dengan `sudo xbps-install -S`.

**T: Saya tidak dapat menemukan paket tertentu menggunakan `xbps-query`.**
**J:** Pastikan Anda telah menjalankan `sudo xbps-install -S` setelah menambahkan repositori. Jika masih tidak muncul, paket tersebut mungkin tidak tersedia untuk arsitektur spesifik Anda. Periksa Mesin Pencari Web kami untuk memverifikasi apakah paket tersebut ada untuk arsitektur Anda.

**T: Mesin pencari web menampilkan "Repositori tidak tersedia" atau status kosong (∅).**
**J:** Ini biasanya berarti deployment GitHub Pages masih memproses push terbaru, atau file `packages.json` sedang dibuat oleh pipeline CI/CD kami. Harap tunggu beberapa menit dan muat ulang halaman.

**T: Mesin pencari web menampilkan error "Rate-limit" (403).**
**J:** Jika file `packages.json` untuk sementara tidak tersedia, mesin pencari akan beralih (*fallback*) ke API GitHub, yang memiliki batas ketat 60 permintaan per jam per IP. Harap tunggu beberapa menit atau coba lagi nanti.

---

**T4n Labs** ◉ **Gh0sT4n**  
*Dibangun untuk komunitas, oleh komunitas.*