# T4n OS Repository - Panduan Developer & Maintainer

Selamat datang di infrastruktur repositori T4n OS. Dokumen ini ditujukan untuk developer dan maintainer yang ingin membangun, mengemas, dan mendeploy perangkat lunak ke repositori T4n OS (`repo-glibc`).

## 1. Struktur Repositori

Repositori ini dirancang untuk memisahkan template build, output biner, dan skrip otomatisasi.

```
.
├── .github/workflows/       # Otomatisasi CI/CD
│   ├── signature.sh         # Menandatangani file .xbps menggunakan GitHub Secrets
│   ├── autogen-index.sh     # Menghasilkan index.html untuk browsing direktori
│   └── autogen-json.sh      # Menghasilkan packages.json untuk frontend web
├── <arch>/                  # Folder biner (x86_64, i686, aarch64, armv6l, armv7l)
│   ├── *.xbps               # Paket biner yang dikompilasi
│   ├── *.xbps.sig2          # Tanda tangan kriptografis (dihasilkan oleh CI)
│   └── index.html           # Directory listing yang dihasilkan otomatis
├── pkg-recipe/              # Template build xbps-src
│   └── <nama_paket>/
│       └── template
├── vtools/
│   └── auto.sh              # Skrip otomatisasi lokal (Build, Copy, Sync)
├── vdocs/                   # Dokumentasi (EN/ID)
├── keys/                    # Kunci publik untuk verifikasi tanda tangan
├── index.html               # Directory listing root (Dihasilkan otomatis)
├── install.sh               # Script instalasi repositori
├── README-ID.md
└── README.md
```

## 2. Prasyarat

Sebelum berkontribusi, pastikan Anda memiliki:

- Void Linux (atau lingkungan yang kompatibel dengan `xbps-src` terinstal).
- Git dan GitHub CLI (`gh`) terinstal dan terautentikasi.
- Akses Write/Owner ke repositori organisasi GitHub `T4n-Labs`.

## 3. Arsitektur yang Didukung

Repositori ini **hanya mendukung 5 arsitektur glibc**:

| No | Arsitektur | Keterangan |
|----|------------|------------|
| 1  | `x86_64`   | PC 64-bit (default untuk kebanyakan desktop) |
| 2  | `armv6l`   | ARM 32-bit (Raspberry Pi 1, Zero) |
| 3  | `armv7l`   | ARM 32-bit (Raspberry Pi 2, 3 dalam mode 32-bit) |
| 4  | `aarch64`  | ARM 64-bit (Raspberry Pi 3/4 dalam mode 64-bit, Apple Silicon) |
| 5  | `i686`     | PC 32-bit (legacy) |

> ️ **Catatan**: Arsitektur `musl` (seperti `x86_64-musl`) **tidak didukung** oleh repositori ini.

## 4. Alur Kerja Lokal (`vtools/auto.sh`)

Untuk mempercepat proses pengemasan, kami menyediakan `vtools/auto.sh`. Skrip ini menangani pengaturan environment, build, sinkronisasi template, dan pengorganisasian file.

### A. Pengaturan Environment

Jika Anda belum meng-clone sistem build `void-packages`, skrip akan melakukannya untuk Anda dan menjalankan bootstrap awal.

```bash
./vtools/auto.sh --setup
```

> **Catatan**: Menjalankan `--build`, `--copy`, atau `--sync` juga akan otomatis melakukan setup jika `void-packages` belum ada.

### B. Sinkronisasi Template

Fitur ini menyalin template dari `pkg-recipe/<nama>` ke `void-packages/srcpkgs/<nama>` tanpa melakukan build. Berguna untuk testing template sebelum build.

```bash
./vtools/auto.sh --sync
# atau
./vtools/auto.sh -t
```

### C. Build Paket

Skrip membaca variabel `archs` dari template Anda untuk menentukan arsitektur mana yang harus di-build. Sekarang dengan **menu bernomor** untuk kemudahan pemilihan.

```bash
./vtools/auto.sh --build
# atau
./vtools/auto.sh -b
```

**Alur interaktif:**
1. Masukkan nama package (pkgname)
2. Template otomatis disinkronkan ke `srcpkgs/`
3. Pilih arsitektur target dengan menu nomor:
   ```
   [1] x86_64
   [2] armv6l
   [3] armv7l
   [4] aarch64
   [5] i686
   [6] all (semua yang didukung)
   ```
4. Default pilihan adalah arsitektur host Anda
5. Build dimulai (menggunakan flag `-a` untuk cross-compile, tanpa `-A`)

> 💡 **Tips**: Anda bisa memilih multiple arsitektur dengan koma, contoh: `1,3,5`

### D. Copy Biner ke Repositori

Setelah build selesai, pindahkan file `.xbps` yang telah dikompilasi dari environment build ke folder arsitektur yang sesuai di repositori ini.

```bash
./vtools/auto.sh --copy
# atau
./vtools/auto.sh -c
```

**Fitur Cleanup Otomatis**: Script akan otomatis mendeteksi dan menghapus versi lama dari package yang sama di folder tujuan. Contoh: jika `tpkg-1.1.0_1.x86_64.xbps` disalin, maka `tpkg-1.0_1.x86_64.xbps` akan otomatis dihapus.

> **Default path**: `void-packages/hostdir/binpkgs`

## 5. Membuat Paket Baru

Setiap paket memerlukan template build yang terletak di `pkg-recipe/<nama_paket>/template`.

### Contoh Template (`pkg-recipe/zvc/template`):

```bash
pkgname=zvc
version=1.0_1
revision=1
archs="x86_64 i686 aarch64 armv6l armv7l"
short_desc="Void package compiler — build xbps from template"
maintainer="T4n Labs <admin@t4n.org>"
distributor="T4n Labs <admin@t4n.org>"
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

### Aturan Parsing `archs`:

- **Tidak ada `archs`** → Support semua 5 arsitektur glibc
- **Token biasa** (`x86_64`) → Hanya glibc
- **Token dengan `*`** (`x86_64*`) → Tanda `*` dihapus, tetap hanya glibc
- **Token dengan `-musl`** (`x86_64-musl`) → Suffix `-musl` dihapus, menjadi `x86_64`

> 💡 **Tips**: Variabel `archs` diparsing secara ketat oleh `auto.sh`. Pastikan formatnya benar (dipisahkan dengan spasi).

## 6. Pipeline CI/CD (GitHub Actions)

Ketika Anda melakukan push perubahan ke branch `main`, GitHub Actions secara otomatis memicu alur kerja berikut:

### Trigger
Workflow hanya berjalan jika ada perubahan di:
- Folder arsitektur (`x86_64/`, `i686/`, `aarch64/`, `armv6l/`, `armv7l/`)
- `pkg-recipe/`
- `install.sh`
- `.github/workflows/**`

### Steps:

1. **Install tools** - Menginstal `xbps` dan dependencies
2. **Checkout repository** - Mengambil kode dari branch `main`
3. **Index and sign packages** - Menandatangani semua file `.xbps` menggunakan `SIGN_KEY` dari GitHub Secrets
4. **Generate index files** - Menghasilkan `index.html` untuk browsing direktori
5. **Generate packages.json** - Memindai file `.xbps` dan template untuk menghasilkan metadata
6. **Assemble site** - Mengumpulkan file yang perlu dilayani ke folder `_site`
7. **Deploy to GitHub Pages** - Mendeploy ke GitHub Pages

> 📝 **Catatan**: File turunan (repodata, `.sig2`, `packages.json`, `index.html`) dibuat di folder `_site` dan langsung dideploy ke Pages. **Tidak di-commit ke repo.**

## 7. Integrasi Frontend (`script.js`)

Mesin pencari paket web T4n OS (`script.js`) mengandalkan file `packages.json` yang dihasilkan untuk menampilkan paket tanpa terkena batas rate-limit API GitHub.

### Strategi Pemuatan Data

- **Sumber Utama**: Mengambil `<arch>/packages.json` untuk semua arsitektur secara paralel (`Promise.allSettled`). Jika satu gagal, akan diabaikan; selama satu berhasil, proses akan berlanjut.
- **Mekanisme Fallback**: Jika TIDAK ADA file `packages.json` yang ditemukan, sistem akan fallback ke GitHub Trees API untuk mem-parsing nama file `.xbps` langsung dari repositori.

> ⚠️ **Peringatan**: GitHub API dibatasi secara ketat hingga 60 permintaan/jam/IP. Error `403` akan menampilkan peringatan rate-limit kepada pengguna. Error `404` diperlakukan sebagai repositori kosong, bukan error.

### Skema `packages.json` yang Wajib Dipenuhi

Skrip `autogen-json.sh` menghasilkan file ini, namun jika Anda membuatnya secara manual atau melakukan debugging, formatnya harus persis seperti ini:

```json
{
  "packages": [
    {
      "name": "zvc",
      "version": "1.0",
      "arch": "x86_64",
      "filename": "zvc-1.0_1.x86_64.xbps",
      "size": 184320,
      "desc": "Void package compiler — build xbps from template"
    }
  ]
}
```

**Catatan**: 
- `name`, `version`, dan `arch` wajib ada
- `size` dan `desc` (dipetakan dari `short_desc`) bersifat opsional namun sangat disarankan untuk UI
- `version` tanpa revisi (`"1.0"`); revisi tetap ada di `filename` (`"zvc-1.0_1.x86_64.xbps"`)

## 8. Keamanan & Manajemen Secrets

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

> ⚠️ **PERINGATAN KEAMANAN KRITIS**:
> - JANGAN PERNAH meng-commit `private.pem` ke repositori.
> - Pastikan `private.pem` secara eksplisit terdaftar di `.gitignore` Anda.
> - Kunci publik (`private.pem.pub`) dapat di-commit dengan aman ke direktori `keys/` agar dapat diunduh dan diverifikasi tanda tangannya oleh pengguna.
> - Metadata kunci publik juga otomatis disematkan ke dalam `repodata` oleh `xbps-rindex`.

## 9. Checklist Deployment

Ikuti daftar periksa ini saat menambahkan paket baru ke repositori:

- [ ] Membuat `pkg-recipe/<name>/template` dengan `archs` dan metadata yang benar
- [ ] Menjalankan `./vtools/auto.sh --sync` (opsional, untuk testing template)
- [ ] Menjalankan `./vtools/auto.sh --build` untuk membangun paket
- [ ] Menjalankan `./vtools/auto.sh --copy` untuk menyalin biner & membersihkan versi lama
- [ ] Melakukan commit: `git add . && git commit -m "feat: add <name> <version>"`
- [ ] Melakukan push ke GitHub: `git push`
- [ ] Memverifikasi GitHub Actions berhasil diselesaikan (Cek tab "Actions")
- [ ] Memverifikasi paket muncul di mesin pencari web (`repo.t4nlabs.web.id/`)
- [ ] Memverifikasi paket dapat diinstal via `xbps-install`

## 10. Troubleshooting

### Build Gagal
- Pastikan template memiliki syntax yang benar
- Cek log output dari `xbps-src` untuk error detail
- Pastikan dependencies build terinstal di host

### `packages.json` Tidak Dibuat
- File ini hanya dibuat di CI/CD, tidak di-commit ke repo
- Cek log GitHub Actions di tab "Actions" untuk error
- Pastikan folder arsitektur (`x86_64/`, dll) memiliki file `.xbps`

### Versi Lama Tidak Terhapus
- Pastikan menjalankan `./vtools/auto.sh --copy` (bukan copy manual)
- Script akan otomatis mendeteksi nama package dan menghapus versi lama

---

**T4n Labs** ◉ **Gh0sT4n**  
*Memberdayakan ekosistem T4n Labs.*