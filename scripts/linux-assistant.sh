#!/usr/bin/env bash
# Linux-Fixes interactive system detector and setup assistant.
# Safe to run as: curl -fsSL https://raw.githubusercontent.com/mihai209/Linux-Fixes/main/scripts/linux-assistant.sh | bash

set -Eeuo pipefail

readonly VERSION="1.0.0"
readonly REPO_RAW="https://raw.githubusercontent.com/mihai209/Linux-Fixes/main"

say()  { printf '\n\033[1;36m%s\033[0m\n' "$*"; }
info() { printf '  • %s\n' "$*"; }
warn() { printf '\033[1;33m[!] %s\033[0m\n' "$*" >&2; }
die()  { printf '\033[1;31m[ERROR] %s\033[0m\n' "$*" >&2; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }
ask_yes_no() {
    local prompt="$1" answer
    while true; do
        read -r -p "$prompt [y/N]: " answer || return 1
        case "${answer,,}" in
            y|yes) return 0 ;;
            n|no|"") return 1 ;;
            *) printf 'Please answer y or n.\n' ;;
        esac
    done
}
pause() { read -r -p $'\nPress Enter to continue...' _ || true; }

detect_system() {
    say "SYSTEM DETECTION"
    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        info "OS: ${PRETTY_NAME:-unknown}"
        info "ID: ${ID:-unknown} ${VERSION_ID:-}"
    else
        warn "/etc/os-release not found"
    fi
    info "Kernel: $(uname -srmo)"
    info "Architecture: $(uname -m)"
    info "Hostname: $(hostname 2>/dev/null || printf unknown)"
    info "Desktop: ${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-unknown}}"
    info "Session type: ${XDG_SESSION_TYPE:-unknown}"
    info "Shell: ${SHELL:-unknown}"

    if have lscpu; then
        info "CPU: $(lscpu | awk -F: '/Model name|架构|Architecture/ {gsub(/^[ \t]+/,"",$2); print $2; exit}')"
        info "CPU cores/threads: $(nproc 2>/dev/null || printf unknown)"
    fi
    if have free; then info "Memory: $(free -h | awk '/Mem:/ {print $2 " total, " $3 " used"}')"; fi
    if have lsblk; then
        info "Storage devices:"
        lsblk -d -o NAME,SIZE,MODEL,TRAN 2>/dev/null | sed 's/^/      /' || true
    fi

    if have lspci; then
        info "PCI graphics/network/audio devices:"
        lspci -nn 2>/dev/null | grep -Ei 'VGA|3D|Display|Network|Ethernet|Audio' | sed 's/^/      /' || true
        info "Kernel driver bindings (where available):"
        lspci -nnk 2>/dev/null | grep -E '^[0-9a-f]{2}:|Kernel driver in use:|Kernel modules:' | sed 's/^/      /' || true
    else
        warn "lspci not installed; PCI hardware details unavailable"
    fi

    if have lsusb; then
        info "USB devices:"
        lsusb 2>/dev/null | sed 's/^/      /' || true
    fi
    if have ip; then
        info "Network interfaces:"
        ip -brief link 2>/dev/null | sed 's/^/      /' || true
    fi
    if have inxi; then
        info "inxi summary:"
        inxi -Fxxxz 2>/dev/null | sed 's/^/      /' || true
    fi

    say "PACKAGE MANAGERS"
    for cmd in apt apt-get dpkg flatpak snap dnf rpm pacman zypper; do
        if have "$cmd"; then info "$cmd: available"; fi
    done

    say "DEVELOPMENT TOOLS"
    for cmd in git gcc g++ clang cmake ninja make node npm pnpm python3 rustc cargo go; do
        if have "$cmd"; then
            info "$cmd: $( "$cmd" --version 2>/dev/null | head -n1 || printf installed )"
        else
            info "$cmd: not found"
        fi
    done
}

is_apt_system() {
    [[ -r /etc/os-release ]] || return 1
    . /etc/os-release
    [[ "${ID:-}" == ubuntu || "${ID:-}" == debian || " ${ID_LIKE:-} " == *" ubuntu "* || " ${ID_LIKE:-} " == *" debian "* ]]
}

install_apt_packages() {
    local title="$1"; shift
    local -a packages=("$@")
    is_apt_system || { warn "This installer currently supports APT-based Ubuntu/Debian systems only."; return 1; }
    have apt-get || die "apt-get not found"
    say "$title"
    printf 'Packages: %s\n' "${packages[*]}"
    ask_yes_no "Install these packages?" || { info "Skipped."; return 0; }
    sudo apt-get update
    sudo apt-get install -y "${packages[@]}"
}

drivers_menu() {
    say "DRIVERS & HARDWARE"
    if have lspci; then
        lspci -nnk 2>/dev/null | grep -Ei 'VGA|3D|Display|Network|Ethernet|Audio|Kernel driver in use:|Kernel modules:' || true
    fi
    if is_apt_system; then
        if have ubuntu-drivers; then
            say "Ubuntu driver recommendations"
            ubuntu-drivers devices 2>/dev/null || true
        elif [[ -r /etc/os-release ]] && grep -qi ubuntu /etc/os-release; then
            info "ubuntu-drivers is not installed. It is provided by ubuntu-drivers-common."
            if ask_yes_no "Install ubuntu-drivers-common to inspect recommended proprietary drivers?"; then
                install_apt_packages "Installing Ubuntu driver detection utility" ubuntu-drivers-common
                ubuntu-drivers devices 2>/dev/null || true
            fi
        fi
        warn "No driver will be installed automatically. Check the detected hardware and the vendor/Ubuntu recommendation first."
        if have ubuntu-drivers && ask_yes_no "Run 'sudo ubuntu-drivers autoinstall' to install Ubuntu-recommended proprietary drivers?"; then
            sudo ubuntu-drivers autoinstall
        fi
        if ask_yes_no "Install common firmware and Mesa/Vulkan diagnostic support (may be unnecessary on some systems)?"; then
            install_apt_packages "Common firmware and graphics userspace" \
                linux-firmware mesa-vulkan-drivers libvulkan1 mesa-utils vulkan-tools
        fi
    else
        warn "Automatic driver installation is not supported on this distribution."
    fi
}

development_menu() {
    install_apt_packages "C/C++ and build toolchain" \
        build-essential cmake ninja-build pkg-config ccache \
        clang clangd clang-format clang-tidy lld gdb lldb valgrind git git-lfs
    install_apt_packages "Python development tools" python3 python3-venv python3-pip pipx
    if ask_yes_no "Install Node.js and npm from this distribution's repositories?"; then
        install_apt_packages "Node.js tools" nodejs npm
    fi
    if ask_yes_no "Install pnpm using its official installer from get.pnpm.io?"; then
        warn "This downloads and executes the official pnpm install script."
        if ask_yes_no "Continue with the pnpm installer?"; then
            curl -fsSL https://get.pnpm.io/install.sh | sh -
            info "Restart your shell (or reload its profile), then run: pnpm --version"
        fi
    fi
}

multimedia_menu() {
    install_apt_packages "Multimedia diagnostics and codecs" \
        vainfo ffmpeg
}

network_menu() {
    install_apt_packages "Network troubleshooting utilities" \
        curl wget dnsutils iproute2 iputils-ping traceroute ethtool iw rfkill
}

diagnostics_menu() {
    install_apt_packages "System diagnostics" \
        pciutils usbutils inxi lm-sensors smartmontools lshw hwinfo
}


shell_menu() {
    say "ZSH + ATUIN"
    is_apt_system || { warn "Automatic shell installation currently supports APT-based Ubuntu/Debian systems only."; return 1; }

    install_apt_packages "Zsh shell" zsh

    if ! have zsh; then
        warn "Zsh is not available after installation; skipping Atuin shell setup."
        return 1
    fi
    info "Zsh version: $(zsh --version)"

    if ask_yes_no "Set Zsh as your default login shell?"; then
        local zsh_path
        zsh_path="$(command -v zsh)"
        if ! grep -Fxq "$zsh_path" /etc/shells 2>/dev/null; then
            warn "$zsh_path is not listed in /etc/shells; not changing the login shell."
        elif have chsh; then
            chsh -s "$zsh_path"
            info "Default shell changed. Log out and back in for the login shell change to take effect."
        else
            warn "chsh is not installed; cannot change the default shell."
        fi
    fi

    if ask_yes_no "Install Atuin (interactive shell history search) using its official installer?"; then
        have curl || die "curl is required to install Atuin."
        say "Installing Atuin from the official setup.atuin.sh installer"
        curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh -s -- --non-interactive

        local zshrc="${ZDOTDIR:-$HOME}/.zshrc"
        mkdir -p "$(dirname "$zshrc")"
        touch "$zshrc"

        if ! grep -Fq 'atuin init zsh' "$zshrc"; then
            printf '\n# Atuin shell history\neval "$(atuin init zsh)"\n' >> "$zshrc"
        fi
        if ! grep -Fq '.atuin/bin' "$zshrc"; then
            printf '\n# Atuin binary path\nexport PATH="$HOME/.atuin/bin:$PATH"\n' >> "$zshrc"
        fi

        if [[ -x "$HOME/.atuin/bin/atuin" ]]; then
            info "Atuin installed: $("$HOME/.atuin/bin/atuin" --version)"
        elif have atuin; then
            info "Atuin installed: $(atuin --version)"
        else
            warn "Atuin installer finished, but the binary was not found in the expected path."
        fi
        info "Restart the terminal or run: exec zsh"
        info "In Zsh, press Ctrl+R to search command history with Atuin."
    fi
}

main_menu() {
    while true; do
        say "LINUX-FIXES SYSTEM ASSISTANT v$VERSION"
        printf '%s\n' \
          "1) Detect system and hardware (read-only)" \
          "2) Drivers and hardware recommendations" \
          "3) Development tools (C/C++, CMake, Node.js, pnpm, Python)" \
          "4) Multimedia / audio / video diagnostics" \
          "5) Network troubleshooting tools" \
          "6) System diagnostic utilities" \
          "7) Run full detection, then choose categories" \
          "8) Zsh + Atuin shell setup" \
          "0) Exit"
        read -r -p "Choose an option: " choice || exit 0
        case "$choice" in
            1) detect_system; pause ;;
            2) drivers_menu; pause ;;
            3) development_menu; pause ;;
            4) multimedia_menu; pause ;;
            5) network_menu; pause ;;
            6) diagnostics_menu; pause ;;\n            8) shell_menu; pause ;;
            7)
                detect_system
                say "Choose which setup categories you need:"
                ask_yes_no "Review driver recommendations?" && drivers_menu
                ask_yes_no "Install development tools?" && development_menu
                ask_yes_no "Install multimedia diagnostics?" && multimedia_menu
                ask_yes_no "Install network tools?" && network_menu
                ask_yes_no "Install system diagnostics?" && diagnostics_menu
                pause
                ;;
            0) exit 0 ;;
            *) warn "Invalid option." ;;
        esac
    done
}

# When piped from curl, stdin contains the script itself. Reattach prompts to
# the user's terminal so the interactive menu can still read answers.
if [[ ! -t 0 ]]; then
    [[ -r /dev/tty ]] || die "An interactive terminal is required. Run this script in a terminal."
    exec </dev/tty
fi

# Execute unconditionally: this script is also commonly run through curl | bash.
# BASH_SOURCE[0] is not a reliable entrypoint check when Bash reads from stdin.
if ! have sudo; then die "sudo is required for package installation."; fi
if ! have curl; then
    warn "curl is missing. Install it manually with your distribution's package manager before using pnpm or Atuin."
fi
main_menu
