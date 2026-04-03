# CleanUpdateUbuntu

A universal bash script to clean, update, and fix installer issues for Linux systems.

## Supported Distributions

| Package Manager | Distribution |
|----------------|--------------|
| `apt` | Debian, Ubuntu, Linux Mint |
| `dnf` | Fedora, RHEL 8+ |
| `yum` | RHEL 7+, CentOS |
| `pacman` | Arch Linux, Manjaro |
| `pkg` | Termux (Android) — no sudo needed |

## Usage

Run the script:

```bash
bash clean.sh
```

Or make it executable:

```bash
chmod +x clean.sh
./clean.sh
```

## Features

- 🗑️ Clean package cache
- 🧹 Auto-clean old packages
- 📦 Remove unused dependencies
- 📈 Update package list
- 🛫 Check upgradable packages
- 💉 Full system upgrade (with y/n confirmation)

## Confirmation Options

When prompted for full upgrade:
- **`y`** → ✅ Continue upgrade → `SYSTEM UPDATE COMPLETE! 🕌🔥`
- **`n`** → ⛔ Cancel upgrade → `Upgrade dibatalkan. System tetap berjalan normal. 🕌`

## Credits

Inspired by Al-Khwarizmi, the father of algebra ("Al-Jabr").
