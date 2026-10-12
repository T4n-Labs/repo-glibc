# T4n OS Repository - Panduan Developer & Maintainer

Selamat datang di infrastruktur repositori T4n OS. Dokumen ini ditujukan untuk developer dan maintainer yang ingin membangun, mengemas, dan mendeploy perangkat lunak ke repositori T4n OS (`repo-glibc`).

## 1. Struktur Repositori

Repositori ini dirancang untuk memisahkan template build, output biner, dan skrip otomatisasi.

```text
.
├── .github/workflows/       # Otomatisasi CI/CD
│   ├── signature.sh         # Menandatangani file .xbps menggunakan GitHub Secrets
│   ├── autogen-index.sh     # Menghasilkan index.html untuk browsing direktori
│   └── autogen-json.sh      # Menghasilkan packages.json untuk frontend web
├── <arch>/                  # Folder biner (x86_64, i686, aarch64, armv6l, armv7l)
│   ├── *.xbps               # Paket biner yang dikompilasi
│   ├── *.xbps.sig           # Tanda tangan kriptografis (dihasilkan oleh CI)
│   ├── *.xbps.sig2          # Tanda tangan sekunder (dihasilkan oleh CI)
│   ├── index.html           # Directory listing yang dihasilkan otomatis
│   └── packages.json        # Metadata yang dihasilkan otomatis untuk script.js
├── pkg-recipe/              # Template build xbps-src
│   └── <nama_paket>/
│       └── template
├── tools/
│   └── auto.sh              # Skrip otomatisasi lokal (Build & Copy)
├── vdocs/                   # Dokumentasi (EN/ID)
├── index.html               # Directory listing root (Dihasilkan otomatis)
└── README.md
```

## ️ 2. Prasyarat

Sebelum berkontribusi, pastikan Anda memiliki:
1. **Void Linux** (atau lingkungan yang kompatibel dengan `xbps-src` terinstal).
2. **Git** dan **GitHub CLI (`gh`)** terinstal dan terautentikasi.
3. Akses **Write/Owner** ke repositori organisasi GitHub `T4n-Labs`.

## 🚀 3. Alur Kerja Lokal (`tools/auto.sh`)

Untuk mempercepat proses pengemasan, kami menyediakan `tools/auto.sh`. Skrip ini menangani pengaturan environment, build multi-arsitektur, dan pengorganisasian file.

### A. Pengaturan Environment
Jika Anda belum meng-clone sistem build `void-packages`, skrip akan melakukannya untuk Anda dan menjalankan bootstrap awal.
```bash
./tools/auto.sh --setup
# Catatan: Menjalankan --build atau --copy juga akan otomatis melakukan setup jika void-packages belum ada.
```

### B. Build Paket
Skrip membaca variabel `archs` dari template Anda untuk menentukan arsitektur mana yang harus di-build.
```bash
./tools/auto.sh --build
# Meminta nama paket -> Membaca pkg-recipe/<nama>/template -> Menjalankan xbps-src
```

### C. Copy Biner ke Repositori
Setelah build selesai, pindahkan file `.xbps` yang telah dikompilasi dari environment build ke folder arsitektur yang sesuai di repositori ini.
```bash
./tools/auto.sh --copy
# Meminta path sumber (Default: void-packages/hostdir/binpkgs)
# Secara otomatis mem-parsing arsitektur dari nama file (misal: zvc-1.0_1.x86_64.xbps -> x86_64/)
```

##  4. Membuat Paket Baru

Setiap paket memerlukan template build yang terletak di `pkg-recipe/<nama_paket>/template`.

**Contoh Template (`pkg-recipe/zvc/template`):**
```bash
pkgname=zvc
version=1.0_1
revision=1
archs="x86_64 i686 aarch64 armv6l armv7l"
short_desc="Void package compiler — build xbps from template"
maintainer="T4n Labs <admin@t4n.org>"
license="MIT"
homepage="https://github.com/T4n-Labs/zvc"
distfiles="https://github.com/T4n-Labs/zvc/archive/v${version%_*}.tar.gz"
checksum=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

do_build() {
    make
}

do_install() {
    make DESTDIR=$DESTDIR install
}
```
💡 **Tips:** Variabel `archs` diparsing secara ketat oleh `auto.sh`. Pastikan formatnya benar (dipisahkan dengan spasi).

## 5. Pipeline CI/CD (GitHub Actions)

Ketika Anda melakukan push perubahan ke branch `main`, GitHub Actions secara otomatis memicu alur kerja berikut:

1. **`signature.sh`**: 
   - Membaca `SIGN_KEY` dari GitHub Repository Secrets.
   - Menandatangani semua file `.xbps` menggunakan `xbps-rindex`, menghasilkan file `.sig` dan `.sig2`.
2. **`autogen-index.sh`**: 
   - Menghasilkan file `index.html` yang rapi di root dan di dalam setiap folder arsitektur untuk memudahkan penelusuran direktori via GitHub Pages.
3. **`autogen-json.sh`**: 
   - Memindai file `.xbps` dan template untuk menghasilkan `packages.json` di setiap folder arsitektur. File ini adalah sumber data utama untuk frontend web.

## 6. Integrasi Frontend (`script.js`)

Mesin pencari paket web T4n OS (`script.js`) mengandalkan file `packages.json` yang dihasilkan untuk menampilkan paket tanpa terkena batas rate-limit API GitHub.

### Strategi Pemuatan Data
1. **Sumber Utama:** Mengambil `<arch>/packages.json` untuk semua arsitektur secara paralel (`Promise.allSettled`). Jika satu gagal, akan diabaikan; selama satu berhasil, proses akan berlanjut.
2. **Mekanisme Fallback:** Jika TIDAK ADA file `packages.json` yang ditemukan, sistem akan fallback ke **GitHub Trees API** untuk mem-parsing nama file `.xbps` langsung dari repositori. 
   - ⚠️ *Peringatan*: GitHub API dibatasi secara ketat hingga **60 permintaan/jam/IP**. Error `403` akan menampilkan peringatan rate-limit kepada pengguna. Error `404` diperlakukan sebagai repositori kosong, bukan error.

### Skema `packages.json` yang Wajib Dipenuhi
Skrip `autogen-json.sh` menghasilkan file ini, namun jika Anda membuatnya secara manual atau melakukan debugging, formatnya **harus** persis seperti ini (baik sebagai array langsung atau dibungkus dalam objek `packages`):

```json
{
  "packages": [
    {
      "name": "zvc",
      "version": "1.0_1",
      "arch": "x86_64",
      "filename": "zvc-1.0_1.x86_64.xbps",
      "size": 184320,
      "desc": "Void package compiler — build xbps from template"
    }
  ]
}
```
*Catatan: `name`, `version`, dan `arch` wajib ada. `size` dan `desc` (dipetakan dari `short_desc`) bersifat opsional namun sangat disarankan untuk UI.*

## 7. Keamanan & Manajemen Secrets

Untuk menandatangani paket, pipeline CI/CD memerlukan kunci privat RSA berformat PEM.

### Generate Kunci (Pengaturan satu kali)
```bash
ssh-keygen -t rsa -b 4096 -m PEM -f private.pem -N ""
```

### Menambahkan ke GitHub Secrets
Gunakan GitHub CLI untuk menyuntikkan kunci secara aman ke repositori:
```bash
gh secret set SIGN_KEY -R T4n-Labs/repo-glibc < private.pem
```

⚠️ **PERINGATAN KEAMANAN KRITIS:**
- **JANGAN PERNAH** meng-commit `private.pem` ke repositori.
- Pastikan `private.pem` secara eksplisit terdaftar di `.gitignore` Anda.
- Kunci publik (`private.pem.pub`) dapat di-commit dengan aman ke direktori `keys/` agar dapat diunduh dan diverifikasi tanda tangannya oleh pengguna.
- Metadata kunci publik juga otomatis disematkan ke dalam `repodata` oleh `xbps-rindex`.


## 8. Checklist Deployment

Ikuti daftar periksa ini saat menambahkan paket baru ke repositori:

- [ ] Membuat `pkg-recipe/<name>/template` dengan `archs` dan metadata yang benar.
- [ ] Menjalankan `./tools/auto.sh --build` untuk membangun paket.
- [ ] Menjalankan `./tools/auto.sh --copy` untuk menyalin biner ke folder arsitektur yang sesuai.
- [ ] Melakukan commit: `git add . && git commit -m "feat: add <name> <version>"`
- [ ] Melakukan push ke GitHub: `git push`
- [ ] Memverifikasi GitHub Actions berhasil diselesaikan (Cek tab "Actions").
- [ ] Memverifikasi paket muncul di mesin pencari web dan dapat diinstal via `xbps-install`.

---

**T4n Labs** ◉ **Gh0sT4n**  
*Memberdayakan ekosistem T4n Labs.*