#!/bin/bash

# ============================================
# CREDENTIAL MANAGEMENT SYSTEM
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/.config"

# Generate random salt (16 bytes hex)
generate_salt() {
    openssl rand -hex 16 2>/dev/null || head -c 16 /dev/urandom | xxd -p 2>/dev/null || cat /proc/sys/kernel/random/uuid | tr -d '-'
}

# Generate random encryption key (32 bytes hex untuk AES-256)
generate_key() {
    openssl rand -hex 32 2>/dev/null || head -c 32 /dev/urandom | xxd -p 2>/dev/null
}

# Hash password dengan konsep berlapis: hash(salt + hash(password) + salt)
hash_password() {
    local password="$1"
    local salt="$2"
    local inner_hash=$(echo -n "${password}" | sha256sum | cut -d' ' -f1)
    echo -n "${salt}${inner_hash}${salt}" | sha256sum | cut -d' ' -f1
}

# Enkripsi password dengan AES-256-CBC
encrypt_password() {
    local password="$1"
    local key="$2"
    echo -n "$password" | openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt -pass pass:"$key" -base64 2>/dev/null
}

# Dekripsi password dengan AES-256-CBC
decrypt_password() {
    local encrypted="$1"
    local key="$2"
    echo "$encrypted" | openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -d -pass pass:"$key" -base64 2>/dev/null
}

# Simpan credential ke file .config (single line base64 encoded)
save_credential() {
    local password="$1"
    local salt=$(generate_salt)
    local enc_key=$(generate_key)
    local hash=$(hash_password "$password" "$salt")
    local encrypted_pass=$(encrypt_password "$password" "$enc_key")
    
    # Gabungkan semua data dengan separator :
    local data="${salt}:${hash}:${enc_key}:${encrypted_pass}"
    
    # Encode base64 dan simpan sebagai single line
    echo -n "$data" | base64 -w 0 > "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE" 2>/dev/null
}

# Load credential dari file .config (silent, return 0 jika sukses)
load_credential() {
    if [[ -f "$CONFIG_FILE" ]]; then
        # Decode base64
        local decoded=$(base64 -d "$CONFIG_FILE" 2>/dev/null)
        if [[ -n "$decoded" ]]; then
            # Parse data yang dipisah :
            IFS=':' read -r SALT HASH ENC_KEY PASSWD <<< "$decoded"
            if [[ -n "$SALT" ]] && [[ -n "$HASH" ]] && [[ -n "$ENC_KEY" ]] && [[ -n "$PASSWD" ]]; then
                return 0
            fi
        fi
    fi
    return 1
}

# Verifikasi password dengan stored hash
verify_password_hash() {
    local password="$1"
    if load_credential; then
        local computed_hash=$(hash_password "$password" "$SALT")
        if [[ "$computed_hash" == "$HASH" ]]; then
            return 0
        fi
    fi
    return 1
}

# Dapatkan password dari credential (dekripsi)
get_stored_password() {
    if load_credential; then
        if [[ -n "$ENC_KEY" ]] && [[ -n "$PASSWD" ]]; then
            SUDO_PASSWORD=$(decrypt_password "$PASSWD" "$ENC_KEY")
            if [[ -n "$SUDO_PASSWORD" ]]; then
                return 0
            fi
        fi
    fi
    return 1
}

# Test apakah sudo membutuhkan password (test dengan /usr/bin/apt clean)
sudo_needs_password() {
    sudo -n /usr/bin/apt clean 2>/dev/null
    return $?
}

# Test password dengan sudo (test dengan /usr/bin/apt clean)
test_sudo_password() {
    local password="$1"
    echo "$password" | sudo -S /usr/bin/apt clean 2>/dev/null
    return $?
}

# Hapus credential
delete_credential() {
    if [[ -f "$CONFIG_FILE" ]]; then
        rm -f "$CONFIG_FILE"
        return 0
    fi
    return 1
}

# ============================================
# END CREDENTIAL MANAGEMENT SYSTEM
# ============================================

clear && echo -e "\e[1;36m╔══════════════════════════════════════╗\e[0m" && echo -e "\e[1;36m║  \e[1;33m 🕌 \"Al-Jabr: seni melengkapi\"\e[1;36m      ║\e[0m" && echo -e "\e[1;36m║      \e[1;33m- Al-Khwarizmi 📖\e[1;36m               ║\e[0m" && echo -e "\e[1;36m╚══════════════════════════════════════╝\e[0m" && echo -e "\e[1;36m╔══════════════════════════════════════╗\e[0m" && echo -e "\e[1;36m║          \e[1;33m 💻 SYSTEM UPDATE 🔥\e[1;36m        ║\e[0m" && echo -e "\e[1;36m╚══════════════════════════════════════╝\e[0m"

# Detect package manager FIRST (sebelum password handling)
# Termux detection MUST come before apt check (Termux has apt as alias)
IS_TERMUX=false
if [[ -n "$TERMUX_VERSION" ]] || [[ "$PREFIX" == *"/data/data/com.termux"* ]]; then
    IS_TERMUX=true
fi

if [[ "$IS_TERMUX" == true ]]; then
    PKG_MANAGER="pkg"
    CLEAN_CMD="pkg clean"
    AUTOCLEAN_CMD="pkg clean"
    AUTOREMOVE_CMD="pkg autoremove -y"
    UPDATE_CMD="pkg update"
    LIST_UPGRADE_CMD="pkg list-upgradable"
    UPGRADE_CMD="pkg upgrade -y"
    TEST_CMD="pkg clean"
    echo -e "\e[1;32m[*] \e[1;37m 📱 Detected: Termux on Android (pkg)\e[0m"
elif command -v apt &> /dev/null; then
    PKG_MANAGER="apt"
    CLEAN_CMD="apt clean"
    AUTOCLEAN_CMD="apt autoclean"
    AUTOREMOVE_CMD="apt autoremove -y"
    UPDATE_CMD="apt update"
    LIST_UPGRADE_CMD="apt list --upgradable"
    UPGRADE_CMD="apt full-upgrade -y"
    TEST_CMD="apt clean"
    echo -e "\e[1;32m[*] \e[1;37m 📦 Detected: Debian/Ubuntu (apt)\e[0m"
elif command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
    CLEAN_CMD="dnf clean all"
    AUTOCLEAN_CMD="dnf clean packages"
    AUTOREMOVE_CMD="dnf autoremove -y"
    UPDATE_CMD="dnf check-update"
    LIST_UPGRADE_CMD="dnf check-upgrade"
    UPGRADE_CMD="dnf upgrade -y"
    TEST_CMD="dnf clean all"
    echo -e "\e[1;32m[*] \e[1;37m 📦 Detected: Red Hat/Fedora (dnf)\e[0m"
elif command -v yum &> /dev/null; then
    PKG_MANAGER="yum"
    CLEAN_CMD="yum clean all"
    AUTOCLEAN_CMD="yum clean packages"
    AUTOREMOVE_CMD="yum autoremove -y"
    UPDATE_CMD="yum check-update"
    LIST_UPGRADE_CMD="yum check-upgrade"
    UPGRADE_CMD="yum update -y"
    TEST_CMD="yum clean all"
    echo -e "\e[1;32m[*] \e[1;37m 📦 Detected: Red Hat/CentOS (yum)\e[0m"
elif command -v pacman &> /dev/null; then
    PKG_MANAGER="pacman"
    CLEAN_CMD="pacman -Sc --noconfirm"
    AUTOCLEAN_CMD="pacman -Scc --noconfirm"
    AUTOREMOVE_CMD="pacman -Rns \$(pacman -Qdtq) --noconfirm 2>/dev/null || true"
    UPDATE_CMD="pacman -Sy"
    LIST_UPGRADE_CMD="pacman -Qu"
    UPGRADE_CMD="pacman -Su --noconfirm"
    TEST_CMD="pacman -Sc --noconfirm"
    echo -e "\e[1;32m[*] \e[1;37m 📦 Detected: Arch Linux (pacman)\e[0m"
else
    echo -e "\e[1;31m❌ Error: No supported package manager found!\e[0m"
    echo -e "\e[1;31m🚫 Unsupported system. Exiting...\e[0m"
    exit 1
fi

# ============================================
# PASSWORD HANDLING FLOW (skip for Termux)
# ============================================

SUDO_PASSWORD=""
PASSWORD_MODE="none"  # none, manual, stored

if [[ "$IS_TERMUX" == true ]]; then
    # Termux tidak punya sudo - langsung set none
    PASSWORD_MODE="none"
    echo -e "\e[1;32m[*] \e[1;37m 📱 Mode Termux: tidak ada sudo, langsung lanjut.\e[0m"
else
# Test apakah sudo butuh password dengan command yang sesuai
sudo_needs_password() {
    sudo -n $TEST_CMD 2>/dev/null
    return $?
}

# Test password dengan sudo
test_sudo_password() {
    local password="$1"
    echo "$password" | sudo -S $TEST_CMD 2>/dev/null
    return $?
}

# Cek apakah sudo butuh password
if sudo_needs_password; then
    # Sudo tidak butuh password (passwordless sudo)
    PASSWORD_MODE="none"
else
    # Sudo butuh password - coba load credential (silent)
    if get_stored_password; then
        # Ada credential, test password
        if test_sudo_password "$SUDO_PASSWORD"; then
            PASSWORD_MODE="stored"
        else
            # Password tidak valid
            echo -e "\e[1;33m[!] \e[1;37m ⚠️  Password tersimpan tidak valid. Mungkin password system berubah?\e[0m"
            echo -e "\e[1;33m[?] \e[1;37m Pilih tindakan:\e[0m"
            echo -e "    \e[1;37m1\e[0m) Update password sekarang (timpa credential lama)"
            echo -e "    \e[1;37m2\e[0m) Hapus credential, input manual untuk sesi ini"
            echo -e "    \e[1;37m3\e[0m) Exit tanpa melakukan apa-apa"
            read -p $'\e[1;33m[?] \e[1;37m Pilihan Anda (1/2/3): \e[0m' choice
            case $choice in
                1)
                    read -s -p $'\e[1;33m[?] \e[1;37m Masukkan password sudo baru: \e[0m' SUDO_PASSWORD
                    echo
                    if test_sudo_password "$SUDO_PASSWORD"; then
                        save_credential "$SUDO_PASSWORD"
                        PASSWORD_MODE="stored"
                        echo -e "\e[1;32m[*] \e[1;37m ✅ Password berhasil diupdate dan disimpan.\e[0m"
                    else
                        echo -e "\e[1;31m❌ Password salah. Exiting...\e[0m"
                        exit 1
                    fi
                    ;;
                2)
                    delete_credential
                    read -s -p $'\e[1;33m[?] \e[1;37m Masukkan password sudo: \e[0m' SUDO_PASSWORD
                    echo
                    if test_sudo_password "$SUDO_PASSWORD"; then
                        PASSWORD_MODE="manual"
                        echo -e "\e[1;32m[*] \e[1;37m ✅ Password valid (tidak disimpan).\e[0m"
                    else
                        echo -e "\e[1;31m❌ Password salah. Exiting...\e[0m"
                        exit 1
                    fi
                    ;;
                3)
                    echo -e "\e[1;31m⛔ Dibatalkan. Exiting...\e[0m"
                    exit 0
                    ;;
                *)
                    echo -e "\e[1;31m❌ Pilihan tidak valid. Exiting...\e[0m"
                    exit 1
                    ;;
            esac
        fi
    else
        # Tidak ada credential tersimpan (first run)
        echo -e "\e[1;33m[!] \e[1;37m ⚠️  Sudo memerlukan password.\e[0m"
        read -p $'\e[1;33m[?] \e[1;37m Simpan password untuk sesi berikutnya? (y/n): \e[0m' save_choice
        case $save_choice in
            [Yy]*)
                read -s -p $'\e[1;33m[?] \e[1;37m Masukkan password sudo: \e[0m' SUDO_PASSWORD
                echo
                if test_sudo_password "$SUDO_PASSWORD"; then
                    save_credential "$SUDO_PASSWORD"
                    PASSWORD_MODE="stored"
                    echo -e "\e[1;32m[*] \e[1;37m ✅ Password berhasil disimpan. Login berikutnya tidak perlu input manual.\e[0m"
                else
                    echo -e "\e[1;31m❌ Password salah. Exiting...\e[0m"
                    exit 1
                fi
                ;;
            [Nn]*)
                read -s -p $'\e[1;33m[?] \e[1;37m Masukkan password sudo: \e[0m' SUDO_PASSWORD
                echo
                if test_sudo_password "$SUDO_PASSWORD"; then
                    PASSWORD_MODE="manual"
                    echo -e "\e[1;32m[*] \e[1;37m ✅ Password valid (tidak disimpan).\e[0m"
                else
                    echo -e "\e[1;31m❌ Password salah. Exiting...\e[0m"
                    exit 1
                fi
                ;;
            *)
                echo -e "\e[1;31m❌ Pilihan tidak valid. Exiting...\e[0m"
                exit 1
                ;;
        esac
    fi
fi
fi  # end of Termux skip

# Fungsi untuk menjalankan command (Termux tanpa sudo)
run_sudo_cmd() {
    local cmd="$1"
    if [[ "$IS_TERMUX" == true ]]; then
        bash -c "$cmd"
    elif [[ "$PASSWORD_MODE" == "stored" ]] || [[ "$PASSWORD_MODE" == "manual" ]]; then
        echo "$SUDO_PASSWORD" | sudo -S bash -c "$cmd"
    else
        sudo bash -c "$cmd"
    fi
}

# ============================================
# END PASSWORD HANDLING FLOW
# ============================================

echo -e "\e[1;32m[*] \e[1;37m 🗑️  Membersihkan cache...\e[0m" && run_sudo_cmd "$CLEAN_CMD" && echo -e "\e[1;32m[*] \e[1;37m 🧹 Auto-clean packages...\e[0m" && run_sudo_cmd "$AUTOCLEAN_CMD" && echo -e "\e[1;32m[*] \e[1;37m 📦 Menghapus packages tidak terpakai...\e[0m" && run_sudo_cmd "$AUTOREMOVE_CMD" && echo -e "\e[1;32m[*] \e[1;37m 📈 Updating package list...\e[0m" && run_sudo_cmd "$UPDATE_CMD" && echo -e "\e[1;32m[*] \e[1;37m 🛫 Cek packages yang bisa diupgrade...\e[0m" && run_sudo_cmd "$LIST_UPGRADE_CMD"

echo -e "\e[1;32m[*] \e[1;37m 💉 Full system upgrade...\e[0m"
read -p $'\e[1;33m[?] \e[1;37m Lanjutkan upgrade? (y/n): \e[0m' -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    run_sudo_cmd "$UPGRADE_CMD"
    echo -e "\e[1;32m✅ \e[1;33mSYSTEM UPDATE COMPLETE! 🕌🔥\e[0m"
else
    echo -e "\e[1;31m⛔ \e[1;33mUpgrade dibatalkan. System tetap berjalan normal. 🕌\e[0m"
    exit 0
fi
