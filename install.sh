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

# Clean up
if [ "$IS_LOCAL" = false ]; then
  rm -rf "$TEMP_DIR"
fi

echo ""
status_success "Installation Complete!"
echo -e "\nYou can now use ${PURPLE}bimagic${NC} or the alias ${PURPLE}wz${NC} to start."
echo -e "Make sure ${CYAN}GITHUB_USER${NC} and ${CYAN}GITHUB_TOKEN${NC} are set."

# Check PATH
if [[ ":$PATH:" != ":$TARGET_DIR:"* ]]; then
  echo ""
  status_warn "$TARGET_DIR is not in your PATH."
  echo -e "   Add it to your shell profile:\n   ${CYAN}echo 'export PATH=\"\$PATH:$TARGET_DIR\"' >> ~/.bashrc${NC}"
fi
