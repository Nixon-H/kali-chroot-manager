#!/bin/bash
# Author: [|-§ Nixon §-|]
# Kali Chroot Manager for Debian 13 (Trixie)

set -euo pipefail
readonly CHROOT_DIR="/opt/kali-chroot"

GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

export DEBIAN_FRONTEND=noninteractive

trap cleanup_mounts EXIT

show_menu() {
    clear
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${YELLOW}       Kali Chroot Manager — Debian 13${RESET}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
    echo "1.  Install Kali chroot environment"
    echo "2.  Enter existing Kali chroot"
    echo "3.  Uninstall (remove all chroot data)"
    echo "4.  Exit"
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

install_chroot() {
    echo "Checking network connectivity..."
    if ! ping -c1 -W2 archive.kali.org &>/dev/null; then
        echo -e "${RED}Error: Internet connectivity issue. Please check your network.${RESET}"
        return 1 # Return to menu
    fi
    echo "Network is online."

    echo "Removing any old Kali repo traces from host..."
    sudo rm -f /etc/apt/sources.list.d/kali.list \
                /etc/apt/preferences.d/kali.pref \
                /etc/apt/trusted.gpg.d/kali-archive-keyring.gpg || true

    echo "Updating Debian..."
    sudo apt update -y

    echo "Installing required base tools..."
    sudo apt install -y debootstrap curl gnupg locales

    echo "Creating Kali chroot directory at $CHROOT_DIR..."
    sudo mkdir -p "$CHROOT_DIR"

    echo "Bootstrapping minimal Kali system (this may take several minutes)..."
    sudo debootstrap --arch=amd64 --variant=minbase kali-rolling "$CHROOT_DIR" http://http.kali.org/kali

    echo "Binding host filesystems..."
    for fs in dev dev/pts proc sys; do
        # Skip binding if already mounted
        grep -q "$CHROOT_DIR/$fs" /proc/mounts || sudo mount --bind "/$fs" "$CHROOT_DIR/$fs"
    done

    echo "Copying DNS configuration..."
    sudo cp /etc/resolv.conf "$CHROOT_DIR/etc/"

    echo "Configuring Kali environment inside chroot..."
    sudo chroot "$CHROOT_DIR" /bin/bash <<EOF
        set -e
        export DEBIAN_FRONTEND=noninteractive

        echo 'Installing essentials inside Kali chroot...'
        apt update -y
        apt install -y curl gnupg ca-certificates locales dialog liblocale-gettext-perl

        echo 'Importing Kali archive signing key...'
        curl -fsSL https://archive.kali.org/archive-key.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/kali-archive-keyring.gpg

        echo 'Updating Kali repositories...'
        apt update -y

        echo 'Generating and fixing UTF-8 locale...'
        # Set vars *before* generation for robustness
        export LANG=en_US.UTF-8
        export LC_ALL=en_US.UTF-8
        grep -q 'en_US.UTF-8' /etc/locale.gen || echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
        locale-gen --purge
        localedef -i en_US -f UTF-8 en_US.UTF-8 || true
        update-locale LANG=en_US.utf8 LC_ALL=en_US.utf8

        echo 'export LANG=en_US.utf8' >> /root/.bashrc
        echo 'export LC_ALL=en_US.utf8' >> /root/.bashrc
        echo 'unset LC_ALL' >> /root/.bashrc
        echo 'export LANGUAGE=en_US:en' >> /root/.bashrc

        echo 'Cleaning up apt cache...'
        apt clean

        echo 'Locale successfully configured (en_US.utf8)'
        echo 'Kali chroot setup complete!'
EOF

    echo -e "${GREEN}Installation complete!${RESET}"
    echo "You can enter it anytime with: sudo chroot $CHROOT_DIR /bin/bash --login"
    read -p "Do you want to enter the chroot now? [Y/n] " ans
    if [[ $ans =~ ^[Yy]$ || -z $ans ]]; then
        enter_chroot
    fi
    # cleanup_mounts will be called automatically by the trap
}

enter_chroot() {
    if [ ! -d "$CHROOT_DIR/bin" ]; then
        echo -e "${RED}Error: $CHROOT_DIR does not seem to be a valid chroot environment.${RESET}"
        echo "Please install it first (Option 1)."
        return 1
    fi
    echo "Mounting required filesystems..."
    for fs in dev dev/pts proc sys; do
        grep -q "$CHROOT_DIR/$fs" /proc/mounts || sudo mount --bind "/$fs" "$CHROOT_DIR/$fs"
    done
    sudo cp /etc/resolv.conf "$CHROOT_DIR/etc/" 2>/dev/null || true
    echo "Entering Kali chroot (type 'exit' to return)..."
    sudo chroot "$CHROOT_DIR" /bin/bash --login
    # cleanup_mounts will be called automatically by the trap
}

cleanup_mounts() {
    # This function is called by the 'trap' on EXIT
    echo "Cleaning up mounts..."
    for fs in dev/pts dev proc sys; do
        if grep -q "$CHROOT_DIR/$fs" /proc/mounts; then
            sudo umount -lf "$CHROOT_DIR/$fs"
        fi
    done
}

uninstall_chroot() {
    echo -e "${YELLOW}WARNING: This will permanently remove $CHROOT_DIR and all data inside.${RESET}"
    read -p "Are you sure you want to remove the Kali chroot completely? [y/N]: " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "Uninstall cancelled."
        return
    fi

    echo "Unmounting any mounted filesystems..."

    cleanup_mounts

    echo "Removing $CHROOT_DIR..."
    sudo rm -rf "$CHROOT_DIR"

    echo "Cleaning old configs..."
    sudo rm -f /etc/apt/sources.list.d/kali.list /etc/apt/preferences.d/kali.pref /etc/apt/trusted.gpg.d/kali-archive-keyring.gpg

    echo -e "${GREEN}Kali chroot fully removed.${RESET}"
}

while true; do
    show_menu
    read -p "Select an option [1-4]: " choice
    case $choice in
        1) install_chroot ;;
        2) enter_chroot ;;
        3) uninstall_chroot ;;
        4) echo "Exiting Kali Chroot Manager."; exit 0 ;;
        *) echo -e "${RED}Invalid option! Please try again.${RESET}" ;;
    esac
    read -p "Press Enter to continue..." temp
done
