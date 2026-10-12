# T4n OS Repository - glibc • [ID](README-ID.md)

Official XBPS (X Binary Package System) package repository for **T4n OS** based on `glibc`. This repository provides pre-compiled, automatically signed, and ready-to-use binary packages for various architectures.

🔍 **Search Packages:** Use our web-based package search engine at **[repo.t4nlabs.web.id/site/glibc.html](https://repo.t4nlabs.web.id/site/glibc.html)** to easily browse, filter, and find all available packages.

## Supported Architectures
- `x86_64` (64-bit PC)
- `i686` (32-bit PC)
- `aarch64` (64-bit ARM)
- `armv6l` & `armv7l` (32-bit ARM)

## Quick Start: Setup Repository

Follow these 3 easy steps to start using the T4n OS repository:

**1. Add the repository configuration**  
Match your system's architecture (example below for `x86_64`):
```bash
echo 'repository=https://t4n-labs.github.io/repo-glibc/x86_64' | sudo tee /etc/xbps.d/10-glibc.conf
```

**2. Synchronize the package database**  
Update your local index so the system recognizes the new packages:
```bash
sudo xbps-install -S
```

**3. Install Packages**  
Search for and install the packages you need:
```bash
xbps-query -Rs package_name
sudo xbps-install package_name
```

**^ Auto Install**
```sh
curl -sL https://t4n-labs.github.io/repo-glibc/install.sh | sudo sh
```

## Complete Documentation

For in-depth information, troubleshooting guides, or contribution guidelines, please refer to our complete documentation:

### Indonesia
- **[Panduan Pengguna](vdocs/ID/USER.md)**: Cara menambah repo, mencari, menginstal, dan troubleshooting untuk pengguna akhir.
- **[Panduan Developer (Maintainer)](vdocs/ID/DEV.md)**: Cara membangun paket, menggunakan `tools/auto.sh`, alur kerja CI/CD, dan manajemen kunci.

### English
- **[User Guide](vdocs/EN/USER.md)**: How to add the repo, search, install packages, and troubleshooting for end users.
- **[Developer Guide](vdocs/EN/DEV.md)**: How to build packages, use `tools/auto.sh`, CI/CD workflow, and key management.

## Repository Structure

```text
.
├── .github/workflows/   # CI/CD automation (signing, indexing, JSON gen)
├── x86_64/              # x86_64 binary packages + packages.json
├── aarch64/             # aarch64 binary packages + packages.json
├── i686/, armv6l/, armv7l/ # Binary packages for other architectures
├── pkg-recipe/          # Package build templates (xbps-src)
├── tools/
│   └── auto.sh          # Local build & copy automation script
├── vdocs/               # Complete documentation (EN/ID)
├── install.sh           # Automatic repository installation script
└── README.md            # This file
```

---

**[T4n Labs](https://t4nlabs.web.id/)** ◉ **[Gh0sT4n](https://gh0st4n.my.id/)**  
*Built for the community, by the community.*