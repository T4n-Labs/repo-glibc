# T4n OS Repository — glibc • [EN](README.md)

Repositori paket XBPS (X Binary Package System) resmi untuk **T4n OS** berbasis `glibc`. Repositori ini menyediakan paket biner yang telah dikompilasi, ditandatangani secara otomatis, dan siap digunakan untuk berbagai arsitektur.

🔍 **Cari Paket:** Gunakan mesin pencari paket web kami di **[repo.t4nlabs.web.id/site/glibc.html](https://repo.t4nlabs.web.id/site/glibc.html)** untuk menjelajahi semua paket yang tersedia dengan mudah.

## Arsitektur yang Didukung
- `x86_64` (PC 64-bit)
- `i686` (PC 32-bit)
- `aarch64` (ARM 64-bit)
- `armv6l` & `armv7l` (ARM 32-bit)

## Cara Setup Repository (Quick Start)

Ikuti 3 langkah mudah ini untuk mulai menggunakan repositori T4n OS:

**1. Tambahkan konfigurasi repositori**  
Sesuaikan dengan arsitektur sistem Anda (contoh di bawah untuk `x86_64`):
```bash
echo 'repository=https://t4n-labs.github.io/repo-glibc/x86_64' | sudo tee /etc/xbps.d/10-glibc.conf
```

**2. Sinkronisasi database paket**  
Perbarui indeks lokal agar sistem mengenali paket baru:
```bash
sudo xbps-install -S
```

**3. Install Packages**  
Cari dan instal paket yang Anda butuhkan:
```bash
xbps-query -Rs package_name
sudo xbps-install package_name
```

**^ Auto Install**
```sh
curl -sL https://t4n-labs.github.io/repo-glibc/install.sh | sudo sh
```

## Dokumentasi Lengkap

Untuk informasi yang lebih mendalam, panduan troubleshooting, atau panduan kontribusi, silakan merujuk ke dokumentasi lengkap berikut:

### Bahasa Indonesia
- **[Panduan Pengguna (End User)](vdocs/ID/USER.md)**: Cara menambah repo, mencari, menginstal, dan troubleshooting untuk pengguna akhir.
- **[Panduan Developer (Maintainer)](vdocs/ID/DEV.md)**: Cara membangun paket, menggunakan `tools/auto.sh`, alur kerja CI/CD, dan manajemen kunci.

### English
- **[End User Guide](vdocs/EN/USER.md)**: How to add the repo, search, install packages, and troubleshooting for end users.
- **[Developer Guide](vdocs/EN/DEV.md)**: How to build packages, use `tools/auto.sh`, CI/CD workflow, and key management.

## Struktur Repositori

```text
.
├── .github/workflows/   # Otomatisasi CI/CD (signing, indexing, JSON gen)
├── x86_64/              # Paket biner x86_64 + packages.json
├── aarch64/             # Paket biner aarch64 + packages.json
├── i686/, armv6l/, armv7l/ # Paket biner untuk arsitektur lainnya
├── pkg-recipe/          # Template build paket (xbps-src)
├── tools/
│   └── auto.sh          # Script otomatisasi build & copy lokal
├── vdocs/               # Dokumentasi lengkap (EN/ID)
├── install.sh           # Script instalasi repositori otomatis
└── README.md            # File ini
```

---

**[T4n Labs](https://t4nlabs.web.id/)** ◉ **[Gh0sT4n](https://gh0st4n.my.id/)**  
*Dibangun untuk komunitas, oleh komunitas.*