#!/bin/bash

# Exit on error
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# GitHub repository URL
REPO_URL="https://github.com/Bimbok/bimagic.git"

clear

# Display ASCII Art with Gradient
echo -e "\033[38;5;51m▗▖   ▄ ▄▄▄▄   ▗▄▖  ▗▄▄▖▄  ▗▄▄▖\033[0m"
echo -e "\033[38;5;45m▐▌   ▄ █ █ █ ▐▌ ▐▌▐▌   ▄ ▐▌   \033[0m"
echo -e "\033[38;5;39m▐▛▀▚▖█ █   █ ▐▛▀▜▌▐▌▝▜▌█ ▐▌   \033[0m"
echo -e "\033[38;5;99m▐▙▄▞▘█       ▐▌ ▐▌▝▚▄▞▘█ ▝▚▄▄▖\033[0m"
echo -e "\033[38;5;135m                              \033[0m"
echo -e "\033[38;5;171m                              \033[0m"
echo -e "\033[38;5;207m                              \033[0m"

echo -e "${CYAN}${BOLD}✨ The Magical CLI Wizard Installer ✨${NC}\n"

# Function to print status
status_info() { echo -e "${BLUE}ℹ${NC}  $1"; }
status_success() { echo -e "${GREEN}✅${NC}  $1"; }
status_error() { echo -e "${RED}❌${NC}  $1"; }
status_warn() { echo -e "${YELLOW}⚠️${NC}  $1"; }

# Check for required tools
status_info "Checking prerequisites..."
if ! command -v git &>/dev/null; then
  status_error "git is not installed. Please install git first."
  exit 1
fi

# Function to install gum
install_gum() {
  status_info "Installing gum..."
  if [ -n "$TERMUX_VERSION" ] && command -v pkg &>/dev/null; then
    pkg install -y gum
  elif command -v brew &>/dev/null; then
    brew install gum
  elif command -v apt &>/dev/null; then
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
    sudo apt update && sudo apt install -y gum
  elif command -v pacman &>/dev/null; then
    sudo pacman -S --noconfirm gum
  elif command -v nix-env &>/dev/null; then
    nix-env -iA nixpkgs.gum
  else
    return 1
  fi
}

# Check for gum dependency
if ! command -v gum &>/dev/null; then
  status_warn "gum is not installed. Bimagic uses gum for its modern UI."
  echo -e -n "   ${BOLD}Do you want to automatically install gum? (Y/n): ${NC}"
  read -r auto_install_gum
  auto_install_gum=${auto_install_gum:-Y}

  if [[ $auto_install_gum =~ ^[Yy]$ ]]; then
    if install_gum; then
      status_success "gum installed successfully!"
    else
      status_error "Failed to install gum automatically."
      echo "   Please install it manually: https://github.com/charmbracelet/gum"
      exit 1
    fi
  else
    status_error "Bimagic cannot run without gum. Installation aborted."
    exit 1
  fi
else
  status_success "gum is ready."
fi

# Check for optional bat dependency
if ! command -v bat &>/dev/null; then
  status_info "bat is not installed. Bimagic uses it for syntax highlighting in The Scrying Glass."
  echo -e -n "   ${BOLD}Do you want to automatically install bat? (y/N): ${NC}"
  read -r auto_install_bat
  auto_install_bat=${auto_install_bat:-N}

  if [[ $auto_install_bat =~ ^[Yy]$ ]]; then
    status_info "Installing bat..."
    if [ -n "$TERMUX_VERSION" ] && command -v pkg &>/dev/null; then
      pkg install -y bat
    elif command -v brew &>/dev/null; then
      brew install bat
    elif command -v apt &>/dev/null; then
      sudo apt update && sudo apt install -y bat
    elif command -v pacman &>/dev/null; then
      sudo pacman -S --noconfirm bat
    elif command -v nix-env &>/dev/null; then
      nix-env -iA nixpkgs.bat
    else
      status_warn "Could not install bat automatically. You can install it manually for a better experience."
    fi
  else
    status_info "Skipping bat installation. Bimagic will work without it."
  fi
else
  status_success "bat is ready (optional)."
fi

# Locate the bimagic script
if [ -f "./bimagic" ]; then
  status_info "Using local bimagic script..."
  SOURCE_PATH="./bimagic"
  IS_LOCAL=true
else
  status_info "Fetching bimagic from GitHub..."
  TEMP_DIR=$(mktemp -d)
  git clone "$REPO_URL" "$TEMP_DIR"
  SOURCE_PATH="$TEMP_DIR/bimagic"
  IS_LOCAL=false
fi

# Determine the target directory
if [ -n "$TERMUX_VERSION" ]; then
  TARGET_DIR="$PREFIX/bin"
  USE_SUDO=false
elif [ -d "$HOME/bin" ] && [ -w "$HOME/bin" ]; then
  TARGET_DIR="$HOME/bin"
  USE_SUDO=false
else
  TARGET_DIR="/usr/local/bin"
  USE_SUDO=true
fi

# Installation step
status_info "Installing to ${TARGET_DIR}..."

if [ "$USE_SUDO" = true ]; then
  sudo mkdir -p "$TARGET_DIR"
  sudo cp "$SOURCE_PATH" "$TARGET_DIR/bimagic"
  sudo chmod +x "$TARGET_DIR/bimagic"
  sudo ln -sf "$TARGET_DIR/bimagic" "$TARGET_DIR/wz"
else
  mkdir -p "$TARGET_DIR"
  cp "$SOURCE_PATH" "$TARGET_DIR/bimagic"
  chmod +x "$TARGET_DIR/bimagic"
  ln -sf "$TARGET_DIR/bimagic" "$TARGET_DIR/wz"
fi

# Create default theme.wz
CONFIG_DIR="$HOME/.config/bimagic"
THEME_FILE="$CONFIG_DIR/theme.wz"

if [ ! -f "$THEME_FILE" ]; then
  status_info "Creating default theme.wz..."
  mkdir -p "$CONFIG_DIR"
  cat <<EOF >"$THEME_FILE"
# Bimagic Theme Configuration
# You can use ANSI color numbers (0-255) or Hex codes (#RRGGBB)

# Primary color for banners and highlights
BIMAGIC_PRIMARY="212"

# Secondary/Accent color
BIMAGIC_SECONDARY="51"

# Success color (for status messages)
BIMAGIC_SUCCESS="46"

# Error color
BIMAGIC_ERROR="196"

# Warning color
BIMAGIC_WARNING="214"

# Info/Cyan color
BIMAGIC_INFO="39"

# Muted color for hints and footer
BIMAGIC_MUTED="240"

# Banner Gradients (ANSI 0-255)
BANNER_COLOR_1="51"
BANNER_COLOR_2="45"
BANNER_COLOR_3="39"
BANNER_COLOR_4="99"
BANNER_COLOR_5="135"
EOF
  status_success "Default theme.wz created at $THEME_FILE"
else
  status_info "Existing theme.wz found at $THEME_FILE, skipping creation."
fi

# Clean up
if [ "$IS_LOCAL" = false ]; then
  rm -rf "$TEMP_DIR"
fi

# Function to setup keybindings
# Function to setup keybindings
setup_keybinding() {
  echo ""

  # 1. Detect the user's actual default shell
  local shell_name=$(basename "$SHELL")
  status_info "Detected default shell: $shell_name"
  status_info "Setting up Ctrl+B keybinding..."

  local added=false

  case "$shell_name" in
  "zsh")
    local zsh_rc="$HOME/.zshrc"
    if [ -f "$zsh_rc" ]; then
      # 2. Check for the Bimagic block explicitly
      if ! grep -q "# START BIMAGIC" "$zsh_rc"; then
        # Note: Included the < /dev/tty fix for Zsh widget!
        echo -e "\n# START BIMAGIC\n# Bimagic ZSH integration\nrun_bimagic_widget() {\n  zle -I\n  bimagic < /dev/tty\n  zle reset-prompt\n}\nzle -N run_bimagic_widget\nbindkey '^b' run_bimagic_widget\n# END BIMAGIC" >>"$zsh_rc"
        status_success "Added keybinding to $zsh_rc"
        added=true
      else
        status_info "Keybinding already exists in $zsh_rc. Skipping."
      fi
    fi
    ;;

  "bash")
    local bash_rc="$HOME/.bashrc"
    if [ -f "$bash_rc" ]; then
      if ! grep -q "# START BIMAGIC" "$bash_rc"; then
        echo -e "\n# START BIMAGIC\n# Bimagic Bash integration\nbind -x '\"\\C-b\": bimagic'\n# END BIMAGIC" >>"$bash_rc"
        status_success "Added keybinding to $bash_rc"
        added=true
      else
        status_info "Keybinding already exists in $bash_rc. Skipping."
      fi
    fi
    ;;

  "fish")
    local fish_config="$HOME/.config/fish/config.fish"
    mkdir -p "$(dirname "$fish_config")"
    touch "$fish_config"
    if ! grep -q "# START BIMAGIC" "$fish_config"; then
      echo -e "\n# START BIMAGIC\n# Bimagic Fish integration\nbind \cb 'bimagic; commandline -f repaint'\n# END BIMAGIC" >>"$fish_config"
      status_success "Added keybinding to config.fish"
      added=true
    else
      status_info "Keybinding already exists in config.fish. Skipping."
    fi
    ;;

  *)
    status_warn "Unsupported or unknown shell ($shell_name). Cannot automatically add keybindings."
    ;;
  esac

  if [ "$added" = true ]; then
    status_info "Please restart your terminal or source your config file to apply changes."
  fi
}

setup_keybinding

echo ""
status_success "Installation Complete!"
echo -e "\nYou can now use ${PURPLE}bimagic${NC} or the alias ${PURPLE}wz${NC} to start."
echo -e "Press ${YELLOW}Ctrl + B${NC} in your terminal to quickly open Bimagic."
echo -e "Make sure ${CYAN}GITHUB_USER${NC} and ${CYAN}GITHUB_TOKEN${NC} are set."

# Check PATH
if [[ ":$PATH:" != ":$TARGET_DIR:"* ]]; then
  echo ""
  status_warn "$TARGET_DIR is not in your PATH."
  echo -e "   Add it to your shell profile:\n   ${CYAN}echo 'export PATH=\"\$PATH:$TARGET_DIR\"' >> ~/.bashrc${NC}"
fi
