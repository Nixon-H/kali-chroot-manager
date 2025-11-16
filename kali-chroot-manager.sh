#!/bin/bash
# Author: [|-§ Nixon §-|]
# Kali Chroot Manager for Debian 13 (Trixie)

set -euo pipefail
readonly CHROOT_DIR="/opt/kali-chroot"

SUDO_REFRESH_PID=""
declare -g SPINNER_PID=""
declare -g CLEANUP_RUNNING=false

GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

export DEBIAN_FRONTEND=noninteractive

trap master_cleanup EXIT INT TERM TSTP

check_critical_commands() {
    local missing=0
    local cmd
    for cmd in "$@"; do
        if ! command -v "$cmd" &>/dev/null; then
            echo -e "${RED}[x] CRITICAL: Command '$cmd' not found. Please install it.${RESET}" >&2
            missing=1
        fi
    done
    return $missing
}

ensure_host_packages() {
    local packages=("$@")
    local missing=()
    for pkg in "${packages[@]}"; do
        if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "ok installed"; then
            missing+=("$pkg")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${YELLOW}[*] Missing host packages: ${missing[*]}${RESET}"
        echo -e "${YELLOW}[*] Installing automatically...${RESET}"
        
        START_SPINNER "Updating package lists (apt update)"
        if ! sudo apt-get update -qq 2>/tmp/apt-update-error.log; then
            STOP_SPINNER
            echo -e "${RED}[x] Failed to update package lists${RESET}"
            if [[ -f /tmp/apt-update-error.log ]]; then
                echo -e "${RED}Error details:${RESET}"
                tail -n 10 /tmp/apt-update-error.log
            fi
            return 1
        fi
        STOP_SPINNER

        START_SPINNER "Installing ${#missing[@]} host package(s)"
        if ! sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${missing[@]}" 2>/tmp/apt-install-error.log; then
            STOP_SPINNER
            echo -e "${RED}[x] Failed to install: ${missing[*]}${RESET}"
            if [[ -f /tmp/apt-install-error.log ]]; then
                echo -e "${RED}Error details:${RESET}"
                tail -n 10 /tmp/apt-install-error.log
            fi
            return 1
        fi
        STOP_SPINNER
        hash -r
    fi
    return 0
}

keep_sudo_alive() {
    exec 2>/dev/null
    while true; do
        sudo -v 2>/dev/null || exit 1
        sleep 240
    done
}

START_SPINNER() {
    if [[ -n "${SPINNER_PID:-}" ]] && kill -0 "$SPINNER_PID" 2>/dev/null; then
        kill -9 "$SPINNER_PID" 2>/dev/null || true
        wait "$SPINNER_PID" 2>/dev/null || true
        unset SPINNER_PID
        printf "\033[G\033[K"
    fi
    local processing="${1}"; START_TIME=$(date +%s)
    local chars=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local parent_pid=$$
    (
        trap 'exit 0' EXIT INT TERM TSTP
        while true; do
            local elapsed=$(( $(date +%s) - START_TIME ))
            for char in "${chars[@]}"; do
                kill -0 $parent_pid 2>/dev/null || exit 0
                printf "\033[G${YELLOW}[%s]${RESET} %s ${GREEN}(%ss)${RESET} \033[K" "${char}" "${processing}" "${elapsed}"
                sleep 0.05
            done
        done
    ) &
    SPINNER_PID=$!
}

STOP_SPINNER() {
    if [[ -n "${SPINNER_PID:-}" ]] && kill -0 "$SPINNER_PID" 2>/dev/null; then
        kill -9 "$SPINNER_PID" 2>/dev/null || true
        wait "$SPINNER_PID" 2>/dev/null || true
    fi
    unset SPINNER_PID
    if [[ -n "${START_TIME:-}" ]]; then
        if [[ "$START_TIME" =~ ^[0-9]+$ ]]; then
            local TIME=$(( $(date +%s) - START_TIME ))
        else
            local TIME=0
        fi
    else
        local TIME=0
    fi
    printf "\033[G\033[K${GREEN}[+] %-60s ${GREEN}(%ss)${RESET}\n" "Done" "$TIME"
}

cleanup_mounts() {
    echo -e "\n${YELLOW}Cleaning up chroot mounts...${RESET}"
    for fs in dev/pts dev proc sys; do
        if grep -q "$CHROOT_DIR/$fs" /proc/mounts; then
            sudo umount -lf "$CHROOT_DIR/$fs" 2>/dev/null || true
        fi
    done
}

cleanup_processes() {
    if [[ -n "${SUDO_REFRESH_PID:-}" ]] && kill -0 "$SUDO_REFRESH_PID" 2>/dev/null; then
        kill -TERM "$SUDO_REFRESH_PID" 2>/dev/null || true
        wait "$SUDO_REFRESH_PID" 2>/dev/null || true
    fi
    if [[ -n "${SPINNER_PID:-}" ]] && kill -0 "$SPINNER_PID" 2>/dev/null; then
        kill -9 "$SPINNER_PID" 2>/dev/null || true
        wait "$SPINNER_PID" 2>/dev/null || true
    fi
    printf "\033[G\033[K"
}

master_cleanup() {
    local exit_code=$?
    $CLEANUP_RUNNING && exit $exit_code
    CLEANUP_RUNNING=true
    
    if [[ $(ps -o stat= -p $$ 2>/dev/null) =~ T ]] || [[ $exit_code -eq 130 ]]; then
        echo -e "\n\n${YELLOW}Exiting gracefully due to user request.${RESET}"
    elif [[ $exit_code -ne 0 ]]; then
        echo -e "\n\n${RED}Performing cleanup after error (Code: $exit_code)...${RESET}"
    fi

    STOP_SPINNER
    cleanup_processes
    cleanup_mounts
    
    if [[ $exit_code -eq 0 ]] || [[ $exit_code -eq 130 ]]; then
        echo -e "${GREEN}Cleanup finished.${RESET}"
    fi
    trap - EXIT INT TERM TSTP
    exit $exit_code
}

show_menu() {
    clear
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${YELLOW}        Kali Chroot Manager — Debian 13${RESET}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
    echo "1.  Install Kali chroot environment"
    echo "2.  Enter existing Kali chroot"
    echo "3.  Setup 'kali-login' alias"
    echo "4.  Uninstall (remove all chroot data)"
    echo "5.  Exit"
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

install_chroot() {
    echo -e "${YELLOW}[*] Refreshing sudo timestamp...${RESET}"
    if ! sudo -v; then
        echo -e "${RED}Error: Sudo authentication failed.${RESET}"
        return 1
    fi
    
    keep_sudo_alive >/dev/null 2>&1 &
    SUDO_REFRESH_PID=$!

    echo -e "${YELLOW}[*] Checking and installing host dependencies...${RESET}"
    local host_packages=("debootstrap" "curl" "gnupg" "iputils-ping")
    if ! ensure_host_packages "${host_packages[@]}"; then
        echo -e "${RED}Error: Failed to install host dependencies. Aborting.${RESET}"
        return 1
    fi

    if ! check_critical_commands "sudo" "ping" "debootstrap" "curl" "gpg" "chroot" "mount" "umount"; then
        echo -e "${RED}Error: Critical commands still missing after install attempt. Aborting.${RESET}"
        return 1
    fi
    echo -e "${GREEN}[+] Host dependencies are satisfied.${RESET}"
    
    START_SPINNER "Checking network connectivity"
    if ! ping -c1 -W2 archive.kali.org &>/tmp/ping-test.log; then
        STOP_SPINNER
        echo -e "${RED}Error: Internet connectivity issue. Please check your network.${RESET}"
        if [[ -f /tmp/ping-test.log ]]; then
            echo -e "${RED}Error details:${RESET}"
            tail -n 10 /tmp/ping-test.log
        fi
        return 1
    fi
    rm -f /tmp/ping-test.log
    STOP_SPINNER

    START_SPINNER "Removing any old Kali repo traces from host"
    sudo rm -f /etc/apt/sources.list.d/kali.list \
                 /etc/apt/preferences.d/kali.pref \
                 /etc/apt/trusted.gpg.d/kali-archive-keyring.gpg || true
    STOP_SPINNER

    START_SPINNER "Updating Debian package lists"
    if ! sudo apt update -y >/dev/null 2>/tmp/apt-update-main.log; then
        STOP_SPINNER
        echo -e "${RED}[x] Failed to update Debian package lists${RESET}"
        if [[ -f /tmp/apt-update-main.log ]]; then
            echo -e "${RED}Error details:${RESET}"
            tail -n 15 /tmp/apt-update-main.log
        fi
        echo -e "${YELLOW}Hint: This might be a temporary network issue or repository problem.${RESET}"
        echo -e "${YELLOW}Try running 'sudo apt update' manually to diagnose.${RESET}"
        return 1
    fi
    rm -f /tmp/apt-update-main.log
    STOP_SPINNER

    START_SPINNER "Installing required base tools (debootstrap, gnupg...)"
    if ! sudo apt install -y debootstrap curl gnupg locales >/dev/null 2>/tmp/apt-install-main.log; then
        STOP_SPINNER
        echo -e "${RED}[x] Failed to install base tools${RESET}"
        if [[ -f /tmp/apt-install-main.log ]]; then
            echo -e "${RED}Error details:${RESET}"
            tail -n 15 /tmp/apt-install-main.log
        fi
        return 1
    fi
    rm -f /tmp/apt-install-main.log
    STOP_SPINNER

    START_SPINNER "Creating Kali chroot directory at $CHROOT_DIR"
    if ! sudo mkdir -p "$CHROOT_DIR" &>/tmp/mkdir-chroot.log; then
        STOP_SPINNER
        echo -e "${RED}[x] Failed to create directory $CHROOT_DIR${RESET}"
        if [[ -f /tmp/mkdir-chroot.log ]]; then
            echo -e "${RED}Error details:${RESET}"
            tail -n 10 /tmp/mkdir-chroot.log
        fi
        return 1
    fi
    rm -f /tmp/mkdir-chroot.log
    STOP_SPINNER

    START_SPINNER "Bootstrapping minimal Kali system (this may take several minutes)"
    if ! sudo debootstrap --arch=amd64 --variant=minbase kali-rolling "$CHROOT_DIR" http://http.kali.org/kali &>/tmp/debootstrap.log; then
        STOP_SPINNER
        echo -e "${RED}Error: Debootstrap failed. Check /tmp/debootstrap.log for details.${RESET}"
        if [[ -f /tmp/debootstrap.log ]]; then
            echo -e "${RED}Last 20 lines of debootstrap log:${RESET}"
            tail -n 20 /tmp/debootstrap.log
        fi
        return 1
    fi
    rm -f /tmp/debootstrap.log
    STOP_SPINNER

    START_SPINNER "Binding host filesystems (dev, proc, sys)"
    local mount_log="/tmp/mount-bind.log"
    rm -f "$mount_log"
    for fs in dev dev/pts proc sys; do
        grep -q "$CHROOT_DIR/$fs" /proc/mounts || \
        sudo mount --bind "/$fs" "$CHROOT_DIR/$fs" 2>> "$mount_log"
    done
    # Check if the last one succeeded as a test
    if ! grep -q "$CHROOT_DIR/sys" /proc/mounts; then
        STOP_SPINNER
        echo -e "${RED}[x] Failed to bind filesystems${RESET}"
        if [[ -f "$mount_log" ]]; then
            echo -e "${RED}Error details:${RESET}"
            tail -n 10 "$mount_log"
        fi
        return 1
    fi
    rm -f "$mount_log"
    STOP_SPINNER

    START_SPINNER "Copying DNS configuration"
    if ! sudo cp /etc/resolv.conf "$CHROOT_DIR/etc/" &>/tmp/cp-resolv.log; then
        STOP_SPINNER
        echo -e "${RED}[x] Failed to copy /etc/resolv.conf${RESET}"
        if [[ -f /tmp/cp-resolv.log ]]; then
            echo -e "${RED}Error details:${RESET}"
            tail -n 10 /tmp/cp-resolv.log
        fi
        return 1
    fi
    rm -f /tmp/cp-resolv.log
    STOP_SPINNER

    START_SPINNER "Configuring Kali environment inside chroot (apt, locales...)"
    if ! sudo chroot "$CHROOT_DIR" /bin/bash <<EOF &>/tmp/chroot-config.log
        set -e
        export DEBIAN_FRONTEND=noninteractive

        apt update -y
        apt install -y curl gnupg ca-certificates locales dialog liblocale-gettext-perl

        curl -fsSL https://archive.kali.org/archive-key.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/kali-archive-keyring.gpg
        apt update -y

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

        apt clean
EOF
    then
        STOP_SPINNER
        echo -e "${RED}[x] Failed to configure chroot environment${RESET}"
        if [[ -f /tmp/chroot-config.log ]]; then
            echo -e "${RED}Error details:${RESET}"
            tail -n 20 /tmp/chroot-config.log
        fi
        return 1
    fi
    rm -f /tmp/chroot-config.log
    STOP_SPINNER

    echo -e "${GREEN}Installation complete!${RESET}"
    echo "You can enter it anytime with Option 2 or: sudo chroot $CHROOT_DIR /bin/bash --login"
    
    if [[ -n "${SUDO_REFRESH_PID:-}" ]] && kill -0 "$SUDO_REFRESH_PID" 2>/dev/null; then
        kill "$SUDO_REFRESH_PID" 2>/dev/null || true
    fi
    SUDO_REFRESH_PID=""

    read -p "Do you want to enter the chroot now? [Y/n] " ans
    if [[ $ans =~ ^[Yy]$ || -z $ans ]]; then
        enter_chroot
    fi
}

enter_chroot() {
    if [ ! -d "$CHROOT_DIR/bin" ]; then
        echo -e "${RED}Error: $CHROOT_DIR does not seem to be a valid chroot environment.${RESET}"
        echo "Please install it first (Option 1)."
        return 1
    fi
    
    START_SPINNER "Mounting required filesystems"
    for fs in dev dev/pts proc sys; do
        grep -q "$CHROOT_DIR/$fs" /proc/mounts || sudo mount --bind "/$fs" "$CHROOT_DIR/$fs"
    done
    sudo cp /etc/resolv.conf "$CHROOT_DIR/etc/" 2>/dev/null || true
    STOP_SPINNER

    echo -e "${GREEN}Entering Kali chroot (type 'exit' to return)...${RESET}"
    sudo chroot "$CHROOT_DIR" /bin/bash --login
    
    echo -e "${YELLOW}Returned to host system.${RESET}"
}

setup_alias() {
    local shell_config_file=""
    if [[ "$SHELL" == *"/zsh"* ]]; then
        shell_config_file="$HOME/.zshrc"
    elif [[ "$SHELL" == *"/bash"* ]]; then
        shell_config_file="$HOME/.bashrc"
    else
        echo -e "${YELLOW}Could not detect .zshrc or .bashrc. Trying ~/.profile.${RESET}"
        shell_config_file="$HOME/.profile"
    fi

    if [ ! -f "$shell_config_file" ]; then
        echo -e "${YELLOW}Creating $shell_config_file...${RESET}"
        touch "$shell_config_file"
    fi
    
    # Use single quotes to prevent $CHROOT_DIR from expanding in the file
    local alias_cmd="alias kali-login='sudo chroot $CHROOT_DIR /bin/bash --login'"

    if ! grep -qF "$alias_cmd" "$shell_config_file"; then
        echo -e "${GREEN}[*] Adding alias to $shell_config_file...${RESET}"
        echo -e "\n# Kali Chroot Alias\n$alias_cmd" >> "$shell_config_file"
        echo -e "${GREEN}Alias 'kali-login' added.${RESET}"
        echo -e "${YELLOW}Please run 'source $shell_config_file' or restart your terminal to use it.${RESET}"
    else
        echo -e "${GREEN}[+] Alias 'kali-login' already exists in $shell_config_file.${RESET}"
    fi
}

uninstall_chroot() {
    echo -e "${YELLOW}WARNING: This will permanently remove $CHROOT_DIR and all data inside.${RESET}"
    read -p "Are you sure you want to remove the Kali chroot completely? [y/N]: " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "Uninstall cancelled."
        return
    fi

    echo -e "${YELLOW}[*] Refreshing sudo timestamp for uninstall...${RESET}"
    if ! sudo -v; then
        echo -e "${RED}Error: Sudo authentication failed.${RESET}"
        return 1
    fi
    
    keep_sudo_alive >/dev/null 2>&1 &
    SUDO_REFRESH_PID=$! # Use the global PID

    START_SPINNER "Unmounting any mounted filesystems"
    cleanup_mounts
    STOP_SPINNER

    START_SPINNER "Removing $CHROOT_DIR directory (this can take a long time)"
    if ! sudo rm -rf "$CHROOT_DIR" &>/tmp/uninstall-rm.log; then
        STOP_SPINNER
        echo -e "${RED}[x] Failed to remove $CHROOT_DIR.${RESET}"
        if [[ -f /tmp/uninstall-rm.log ]]; then
            echo -e "${RED}Error details:${RESET}"
            tail -n 10 /tmp/uninstall-rm.log
        fi
        # Let master_cleanup handle the PID kill on error
        return 1
    fi
    rm -f /tmp/uninstall-rm.log
    STOP_SPINNER

    START_SPINNER "Cleaning old host configs"
    sudo rm -f /etc/apt/sources.list.d/kali.list /etc/apt/preferences.d/kali.pref /etc/apt/trusted.gpg.d/kali-archive-keyring.gpg
    STOP_SPINNER

    # Manually kill the sudo loop on success
    if [[ -n "${SUDO_REFRESH_PID:-}" ]] && kill -0 "$SSUDO_REFRESH_PID" 2>/dev/null; then
        kill "$SUDO_REFRESH_PID" 2>/dev/null || true
    fi
    SUDO_REFRESH_PID=""

    echo -e "${GREEN}Kali chroot fully removed.${RESET}"
}

while true; do
    show_menu
    read -p "Select an option [1-5]: " choice
    case $choice in
        1) install_chroot ;;
        2) enter_chroot ;;
        3) setup_alias ;;
        4) uninstall_chroot ;;
        5 | [Ee][Xx][Ii][Tt]) 
           echo "Exiting Kali Chroot Manager."; 
           exit 0 
           ;; 
        *) echo -e "${RED}Invalid option! Please try again.${RESET}" ;;
    esac
    read -p "Press Enter to continue..." temp
done
