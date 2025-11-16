# 🐉 Kali Chroot Manager for Debian

> A powerful, menu-driven Bash utility to seamlessly install, manage, and remove a Kali Linux chroot environment on Debian 13 (Trixie).

[![Debian](https://img.shields.io/badge/Debian-13%20(Trixie)-red.svg)](https://www.debian.org/)
[![Kali](https://img.shields.io/badge/Kali-Rolling-blue.svg)](https://www.kali.org/)

## 📖 Overview

This script automates the creation and management of a Kali Linux chroot environment using `debootstrap`, enabling you to access Kali's extensive penetration testing toolkit directly from your Debian system—no dual-boot, virtual machine, or containers required.

---

## 🎯 Why This Tool Exists

### The Problem: Kali's Instability on Production Systems

Kali Linux is a **rolling-release distribution** built specifically for penetration testing and security auditing. While it's an incredible toolkit for security professionals, it comes with significant drawbacks when used as a daily driver or primary operating system:

#### **Kali's Inherent Challenges:**

1. **Breaking Updates**: Kali's rolling nature means packages are constantly updated, often introducing breaking changes that can render your system unstable or unusable
2. **Bleeding-Edge Packages**: New versions arrive quickly, often without extensive stability testing
3. **System Fragility**: A single `apt upgrade` can break critical system components, desktop environments, or dependencies
4. **Repository Conflicts**: Kali repos can conflict with stable distribution packages, causing dependency hell
5. **Frequent Breakage**: Tools may break between updates, requiring constant troubleshooting
6. **Not Designed for Stability**: Kali explicitly warns users that it's meant for security testing, not as a general-purpose OS

#### **The Debian Advantage:**

Debian, especially the stable release (currently Trixie/13), represents the opposite philosophy:

- **Rock-Solid Stability**: Packages are thoroughly tested before release
- **Predictable Updates**: Security patches only, no surprise feature changes
- **Long-Term Reliability**: Perfect for production environments and daily use
- **Wide Software Support**: Better compatibility with enterprise and mainstream applications
- **Trusted Foundation**: Used by millions as a reliable base system

### The Solution: Best of Both Worlds

This tool allows you to maintain a **stable, reliable Debian system** for your daily work while having **instant access to Kali's security tools** in a completely isolated environment. Think of it as having a security lab that you can enter and exit at will, without ever risking your main system.

#### **Why This Approach Works:**

- ✅ **Zero Risk to Host**: Your Debian system remains untouched and stable
- ✅ **Complete Isolation**: Kali's aggressive updates can't break your Debian installation
- ✅ **Full Tool Access**: Every Kali tool works exactly as intended
- ✅ **Easy Recovery**: If something breaks in Kali, just reinstall the chroot—your Debian system is safe
- ✅ **Professional Workflow**: Stable OS for productivity, Kali for security work
- ✅ **No Performance Overhead**: Unlike VMs, chroot has near-zero performance impact
- ✅ **Instant Switching**: Enter and exit Kali in seconds without rebooting

### Who Is This For?

This tool is ideal for:

- **Security Professionals**: Who need Kali tools but require a stable daily driver
- **Penetration Testers**: Who want to avoid system breaks during critical engagements
- **Students & Learners**: Who want to experiment with Kali without risking their main OS
- **System Administrators**: Who need occasional access to security tools on stable servers
- **Developers**: Who build security tools but need a reliable development environment
- **Former Kali Users**: Who got tired of dealing with constant system breakage

### Why Not Just Use Kali Full-Time?

Many users start with Kali as their main OS, attracted by its comprehensive tool collection. However, they quickly discover:

> *"I just wanted to do some security testing, but after an update, my WiFi stopped working, my display manager broke, and I can't even log in anymore. I've spent more time fixing Kali than actually using it."*

This is the **most common complaint** from Kali users. The distribution itself explicitly states it's not meant for general-purpose use. By using this chroot approach, you get:

- Kali's tools when you need them
- Debian's stability when you don't
- The ability to nuke and rebuild Kali without consequences
- A professional, maintainable setup that won't betray you during important work

### The Chroot Advantage

Unlike dual-booting, VMs, or Docker containers, a chroot provides:

- **Native Performance**: Direct hardware access, no virtualization overhead
- **Shared Resources**: Uses your existing system's kernel and drivers
- **Lightweight**: No hypervisor, minimal disk space
- **Instant Access**: No boot time, no VM startup delay
- **Easy Cleanup**: Remove everything with a single command
- **Network Transparency**: Uses host's network configuration automatically

---

## ⚠️ Security Notice

**This script requires elevated privileges and performs critical system operations:**

- Creates/deletes directories in `/opt`
- Manages filesystem bind mounts
- Installs system packages
- **DESTRUCTIVE**: The uninstall option permanently deletes `/opt/kali-chroot` and all contained data

**Use at your own risk.** Review the script before execution. Recommended for experienced users familiar with chroot environments.

---

## ✨ Features

### Core Functionality

- 🎨 **Intuitive Menu Interface** - Color-coded, easy-to-navigate options
- 🔧 **Automated Setup** - Handles all configuration automatically
- 🔒 **Safe Operations** - Built-in safeguards and cleanup mechanisms
- 🗑️ **Clean Removal** - Complete uninstallation with no leftover traces

### Technical Highlights

- **Smart Filesystem Binding**: Automatically mounts `/dev`, `/proc`, `/sys`, and `/dev/pts`
- **Network Configuration**: Copies host DNS settings for immediate network access
- **Locale Setup**: Pre-configures `en_US.UTF-8` locale for compatibility
- **Keyring Management**: Properly installs and configures Kali archive keys
- **Trap Handling**: Ensures all mounts are cleaned up even on errors or interrupts
- **Idempotent Mounts**: Prevents duplicate mounts when re-entering the chroot

---

## 📋 Prerequisites

### System Requirements

| Requirement | Details |
|------------|---------|
| **Host OS** | Debian 13 (Trixie) |
| **Architecture** | AMD64/x86_64 |
| **User Access** | Account with `sudo` privileges |
| **Network** | Active internet connection |
| **Disk Space** | Minimum 2GB free (recommended 5GB+) |

### Automatic Dependencies

The script will automatically install these packages on your host system:

- `debootstrap` - Creates the minimal Debian/Kali system
- `curl` - Downloads Kali signing keys
- `gnupg` - Manages cryptographic keys
- `iputils-ping` - For network connectivity checks

---

## 🚀 Quick Start

### Installation

1. **Download the script:**

```bash
wget https://raw.githubusercontent.com/Nixon-H/kali-chroot-manager/main/kali-chroot-manager.sh
# Or clone the repository
git clone https://github.com/Nixon-H/kali-chroot-manager.git
cd kali-chroot-manager
```

2. **Make it executable:**

```bash
chmod +x kali-chroot-manager.sh
```

3. **Run the script:**

```bash
./kali-chroot-manager.sh
```

> ⚠️ **Important**: Run as your normal user, **NOT** with `sudo`. The script will prompt for your password when needed.

---

## 📚 Usage Guide

### Main Menu

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        Kali Chroot Manager — Debian 13
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Install Kali chroot environment
2. Enter existing Kali chroot
3. Setup 'kali-login' alias
4. Uninstall (remove all chroot data)
5. Exit

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Select an option [1-5]:
```

### Option 1: Install Kali Chroot Environment

**What it does:**

1. ✅ Verifies internet connectivity
2. 🧹 Removes any conflicting Kali repository configurations from host
3. 📦 Installs required dependencies on Debian host
4. 📁 Creates `/opt/kali-chroot` directory
5. ⬇️ Downloads and installs minimal Kali Rolling base system (5-10 minutes)
6. 🔗 Binds essential host filesystems
7. 🌐 Configures networking (DNS resolution)
8. 🔑 Sets up Kali archive keyring
9. 🌍 Generates `en_US.UTF-8` locale
10. 🎉 Offers to enter the chroot immediately

**First-time setup example:**

```bash
$ ./kali-chroot-manager.sh
# Select option 1
# Wait for installation to complete
# Choose 'Y' to enter chroot or 'n' to return to menu
```

### Option 2: Enter Existing Kali Chroot

**What it does:**

1. ✓ Validates chroot directory exists
2. 🔗 Mounts required filesystems (if not already mounted)
3. 🌐 Updates DNS configuration
4. 🚪 Drops you into a Kali bash login shell

**Inside the chroot:**

```bash
# You're now in Kali Linux!
root@hostname:/# apt update
root@hostname:/# apt install kali-tools-top10
root@hostname:/# nmap -version
root@hostname:/# exit  # Returns to menu
```

### Option 3: Setup 'kali-login' Alias

**What it does:**

1. 🔍 Detects your shell configuration file (`.zshrc`, `.bashrc`, or `.profile`)
2. ✍️ Appends the `alias kali-login='sudo chroot /opt/kali-chroot /bin/bash --login'` command to it
3. 💡 Allows you to type `kali-login` from your host terminal to enter the chroot, instead of using this script or the long command

**After running this option:**

```bash
# Select option 3
[*] Adding alias to /home/user/.zshrc...
Alias 'kali-login' added.
Please run 'source /home/user/.zshrc' or restart your terminal to use it.
```

> **Note:** You must reload your shell config (`source ~/.zshrc`) or open a new terminal for the alias to become active.

### Option 4: Uninstall

**What it does:**

1. ⚠️ Requests confirmation (prevents accidental deletion)
2. 🔓 Unmounts all bound filesystems
3. 🗑️ Permanently removes `/opt/kali-chroot`
4. 🧹 Cleans up any host Kali configurations

**Complete removal:**

```bash
# Select option 4
WARNING: This will permanently remove /opt/kali-chroot and all data inside.
Are you sure you want to remove the Kali chroot completely? [y/N]: y
# Chroot and all data will be deleted
```

### Option 5: Exit

Safely exits the script. The cleanup trap ensures all mounts are properly unmounted if any operations were in progress.

---

## 🛠️ Technical Details

### Directory Structure

```
/opt/kali-chroot/
├── bin/          # Kali binaries
├── boot/         # Boot files
├── dev/          # Device files (bind mount)
├── etc/          # Configuration files
├── home/         # User home directories
├── lib/          # Libraries
├── proc/         # Process information (bind mount)
├── root/         # Root user home
├── sys/          # System information (bind mount)
├── tmp/          # Temporary files
├── usr/          # User programs
└── var/          # Variable data
```

### How It Works

#### Chroot Isolation

The script creates a completely isolated Kali Linux environment at `/opt/kali-chroot`. This directory acts as the root (`/`) for all operations within the chroot, preventing any interference with your host Debian system.

#### Debootstrap Magic

`debootstrap` is Debian's official tool for creating minimal system installations. By pointing it to Kali's repositories, we create a lightweight Kali environment without the overhead of a full installation.

#### Filesystem Binding

```bash
mount --bind /dev /opt/kali-chroot/dev
mount --bind /proc /opt/kali-chroot/proc
mount --bind /sys /opt/kali-chroot/sys
```

These bind mounts allow the chroot to access:

- **`/dev`**: Hardware devices (disks, network interfaces)
- **`/proc`**: Process and system information
- **`/sys`**: Kernel and device data
- **`/dev/pts`**: Pseudo-terminal devices

Without these mounts, most programs would fail to function properly.

#### Exit Trap Safety

```bash
trap master_cleanup EXIT INT TERM TSTP
```

This Bash trap ensures the `master_cleanup` function runs automatically when the script exits, regardless of how it exits (normal termination, error, or Ctrl+C). This prevents orphaned mounts that could cause system issues.

---

## 🔧 Advanced Usage

### Installing Additional Kali Tools

Once inside the chroot:

```bash
# Update package lists
apt update

# Install specific tool categories
apt install kali-tools-top10       # Top 10 security tools
apt install kali-tools-web         # Web application testing
apt install kali-tools-wireless    # Wireless network tools
apt install kali-tools-forensics   # Digital forensics tools

# Or install the full Kali metapackage (requires significant disk space)
apt install kali-linux-everything
```

### Manual Chroot Entry

If you prefer to enter the chroot manually without the script (or use the `kali-login` alias from Option 3):

```bash
# 1. Use the alias (after running Option 3 and sourcing)
kali-login

# 2. The manual way
# Mount filesystems
sudo mount --bind /dev /opt/kali-chroot/dev
sudo mount --bind /dev/pts /opt/kali-chroot/dev/pts
sudo mount --bind /proc /opt/kali-chroot/proc
sudo mount --bind /sys /opt/kali-chroot/sys

# Copy DNS configuration
sudo cp /etc/resolv.conf /opt/kali-chroot/etc/

# Enter chroot
sudo chroot /opt/kali-chroot /bin/bash --login

# After exiting, unmount everything
sudo umount /opt/kali-chroot/{dev/pts,dev,proc,sys}
```

### Custom Locale Configuration

To add additional locales inside the chroot:

```bash
# Enter the chroot
kali-login

# Edit locale.gen
nano /etc/locale.gen
# Uncomment desired locales (e.g., 'de_DE.UTF-8 UTF-8')

# Generate locales
locale-gen

# Set default locale
update-locale LANG=de_DE.UTF-8
```

---

## ❓ Troubleshooting

### Common Issues

#### "Error: Internet connectivity issue"

**Problem**: Cannot reach Kali repositories  
**Solution**:

```bash
# Test connectivity
ping -c 3 archive.kali.org

# Check DNS
cat /etc/resolv.conf

# Verify network interface is up
ip link show
```

#### "chroot: failed to run command '/bin/bash': No such file or directory"

**Problem**: Incomplete installation or corrupted chroot  
**Solution**:

```bash
# Remove and reinstall
./kali-chroot-manager.sh  # Select option 4 (Uninstall)
./kali-chroot-manager.sh  # Select option 1 (Install)
```

#### Package manager errors inside chroot

**Problem**: Apt database locked or corrupted  
**Solution**:

```bash
# Inside chroot
rm /var/lib/dpkg/lock-frontend
rm /var/lib/apt/lists/lock
dpkg --configure -a
apt update
```

#### Locale warnings when running commands

**Problem**: Locale not properly configured  
**Solution**:

```bash
# Inside chroot
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
locale-gen en_US.UTF-8
```

#### Cannot unmount filesystems

**Problem**: Processes still using the chroot  
**Solution**:

```bash
# Find processes using the chroot
lsof | grep /opt/kali-chroot

# Kill any remaining processes
sudo fuser -k /opt/kali-chroot

# Force unmount
sudo umount -lf /opt/kali-chroot/{dev/pts,dev,proc,sys}
```

---

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Commit your changes**: `git commit -m 'Add amazing feature'`
4. **Push to the branch**: `git push origin feature/amazing-feature`
5. **Open a Pull Request**

### Areas for Improvement

- Support for ARM architectures
- Multiple chroot profiles
- Automatic backup before uninstall
- Integration with systemd for auto-mounting
- GUI version using dialog or whiptail

---

## 🙏 Acknowledgments

- Debian Project for `debootstrap`
- Offensive Security for Kali Linux
- The Linux community for chroot documentation

---

## 📞 Support

- 🐛 **Report bugs**: [GitHub Issues](https://github.com/Nixon-H/kali-chroot-manager/issues)

---

## ⚖️ Disclaimer

This tool is intended for **educational and authorized security testing purposes only**. Always ensure you have explicit permission before testing any systems. The authors are not responsible for misuse or damage caused by this script.

---

**Made with ❤️ for the Debian and Kali Linux communities**
