#!/bin/bash

clear && echo -e "\e[1;36m╔══════════════════════════════════════╗\e[0m" && echo -e "\e[1;36m║  \e[1;33m 🕌 \"Al-Jabr: seni melengkapi\"\e[1;36m      ║\e[0m" && echo -e "\e[1;36m║      \e[1;33m- Al-Khwarizmi 📖\e[1;36m               ║\e[0m" && echo -e "\e[1;36m╚══════════════════════════════════════╝\e[0m" && echo -e "\e[1;36m╔══════════════════════════════════════╗\e[0m" && echo -e "\e[1;36m║          \e[1;33m 💻 SYSTEM UPDATE 🔥\e[1;36m        ║\e[0m" && echo -e "\e[1;36m╚══════════════════════════════════════╝\e[0m"

# Detect package manager
if command -v apt &> /dev/null; then
    PKG_MANAGER="apt"
    CLEAN_CMD="sudo apt clean"
    AUTOCLEAN_CMD="sudo apt autoclean"
    AUTOREMOVE_CMD="sudo apt autoremove -y"
    UPDATE_CMD="sudo apt update"
    LIST_UPGRADE_CMD="sudo apt list --upgradable"
    UPGRADE_CMD="sudo apt full-upgrade -y"
    echo -e "\e[1;32m[*] \e[1;37m 📦 Detected: Debian/Ubuntu (apt)\e[0m"
elif command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
    CLEAN_CMD="sudo dnf clean all"
    AUTOCLEAN_CMD="sudo dnf clean packages"
    AUTOREMOVE_CMD="sudo dnf autoremove -y"
    UPDATE_CMD="sudo dnf check-update"
    LIST_UPGRADE_CMD="sudo dnf check-upgrade"
    UPGRADE_CMD="sudo dnf upgrade -y"
    echo -e "\e[1;32m[*] \e[1;37m 📦 Detected: Red Hat/Fedora (dnf)\e[0m"
elif command -v yum &> /dev/null; then
    PKG_MANAGER="yum"
    CLEAN_CMD="sudo yum clean all"
    AUTOCLEAN_CMD="sudo yum clean packages"
    AUTOREMOVE_CMD="sudo yum autoremove -y"
    UPDATE_CMD="sudo yum check-update"
    LIST_UPGRADE_CMD="sudo yum check-update"
    UPGRADE_CMD="sudo yum update -y"
    echo -e "\e[1;32m[*] \e[1;37m 📦 Detected: Red Hat/CentOS (yum)\e[0m"
elif command -v pacman &> /dev/null; then
    PKG_MANAGER="pacman"
    CLEAN_CMD="sudo pacman -Sc --noconfirm"
    AUTOCLEAN_CMD="sudo pacman -Scc --noconfirm"
    AUTOREMOVE_CMD="sudo pacman -Rns \$(pacman -Qdtq) --noconfirm 2>/dev/null || true"
    UPDATE_CMD="sudo pacman -Sy"
    LIST_UPGRADE_CMD="sudo pacman -Qu"
    UPGRADE_CMD="sudo pacman -Su --noconfirm"
    echo -e "\e[1;32m[*] \e[1;37m 📦 Detected: Arch Linux (pacman)\e[0m"
else
    echo -e "\e[1;31m❌ Error: No supported package manager found!\e[0m"
    echo -e "\e[1;31m🚫 Unsupported system. Exiting...\e[0m"
    exit 1
fi

echo -e "\e[1;32m[*] \e[1;37m 🗑️  Membersihkan cache...\e[0m" && $CLEAN_CMD && echo -e "\e[1;32m[*] \e[1;37m 🧹 Auto-clean packages...\e[0m" && $AUTOCLEAN_CMD && echo -e "\e[1;32m[*] \e[1;37m 📦 Menghapus packages tidak terpakai...\e[0m" && $AUTOREMOVE_CMD && echo -e "\e[1;32m[*] \e[1;37m 📈 Updating package list...\e[0m" && $UPDATE_CMD && echo -e "\e[1;32m[*] \e[1;37m 🛫 Cek packages yang bisa diupgrade...\e[0m" && $LIST_UPGRADE_CMD

echo -e "\e[1;32m[*] \e[1;37m 💉 Full system upgrade...\e[0m"
read -p $'\e[1;33m[?] \e[1;37m Lanjutkan upgrade? (y/n): \e[0m' -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    $UPGRADE_CMD
    echo -e "\e[1;32m✅ \e[1;33mSYSTEM UPDATE COMPLETE! 🕌🔥\e[0m"
else
    echo -e "\e[1;31m⛔ \e[1;33mUpgrade dibatalkan. System tetap berjalan normal. 🕌\e[0m"
    exit 0
fi
