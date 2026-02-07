#!/bin/bash

# Bimagic Uninstall Script
echo "Bimagic Uninstaller"
echo "==================="

# Determine installation locations
TARGET_DIRS=("$HOME/bin" "/usr/local/bin")
if [ -n "$PREFIX" ]; then
    TARGET_DIRS=("$PREFIX/bin" "${TARGET_DIRS[@]}")
fi
FOUND_INSTALLS=()

# Check where bimagic is installed
for dir in "${TARGET_DIRS[@]}"; do
    if [[ -f "$dir/bimagic" || -f "$dir/wz" ]]; then
        FOUND_INSTALLS+=("$dir")
        echo "Found Bimagic installation (or alias) in: $dir"
    fi
done

if [[ ${#FOUND_INSTALLS[@]} -eq 0 ]]; then
    echo "Bimagic is not installed on this system."
    exit 0
fi

# Confirm uninstallation
read -p "Are you sure you want to uninstall Bimagic and the 'wz' alias? (y/N): " -r confirm < /dev/tty
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "Uninstallation cancelled."
    exit 0
fi

# Remove bimagic from all found locations
for dir in "${FOUND_INSTALLS[@]}"; do
    echo "Removing Bimagic from $dir..."
    
    # Use sudo if it's /usr/local/bin and NOT in Termux
    if [[ "$dir" == "/usr/local/bin" && -z "$TERMUX_VERSION" ]]; then
        # Need sudo for system directory
        if sudo rm -f "$dir/bimagic" "$dir/wz"; then
            echo "✓ Successfully removed from $dir"
        else
            echo "✗ Failed to remove from $dir (permission issue?)"
        fi
    else
        # User directory or Termux, no sudo needed/available
        if rm -f "$dir/bimagic" "$dir/wz"; then
            echo "✓ Successfully removed from $dir"
        else
            echo "✗ Failed to remove from $dir"
        fi
    fi
done

# Optional: Remove environment variables from shell config
read -p "Do you want to remove GITHUB_USER and GITHUB_TOKEN from your shell config? (y/N): " -r remove_vars < /dev/tty
if [[ $remove_vars =~ ^[Yy]$ ]]; then
    SHELL_FILES=("$HOME/.bashrc" "$HOME/.zshrc")
    
    for file in "${SHELL_FILES[@]}"; do
        if [[ -f "$file" ]]; then
            # Remove lines containing GITHUB_USER or GITHUB_TOKEN
            if grep -q "GITHUB_USER\|GITHUB_TOKEN" "$file"; then
                # Create a backup
                cp "$file" "${file}.backup-$(date +%Y%m%d)"
                
                # Remove the lines
                sed -i '/GITHUB_USER\|GITHUB_TOKEN/d' "$file"
                echo "✓ Removed GitHub variables from $file"
                echo "  A backup was created at ${file}.backup-$(date +%Y%m%d)"
            else
                echo "✓ No GitHub variables found in $file"
            fi
        fi
    done
fi

# Optional: Remove gum if it was installed for Bimagic
if command -v gum &> /dev/null; then
    echo ""
    echo "gum is currently installed on your system."
    read -p "Do you want to remove gum as well? (y/N): " -r remove_gum < /dev/tty
    if [[ $remove_gum =~ ^[Yy]$ ]]; then
        echo "Attempting to remove gum..."
        
        # Try different package managers
        if [ -n "$TERMUX_VERSION" ] && command -v pkg &> /dev/null; then
            echo "Detected Termux - Removing gum via pkg..."
            if pkg uninstall -y gum; then
                echo "✓ Successfully removed gum via pkg"
            else
                echo "✗ Failed to remove gum via pkg"
            fi
        elif command -v apt &> /dev/null; then
            echo "Detected apt package manager"
            if sudo apt remove -y gum 2>/dev/null; then
                echo "✓ Successfully removed gum via apt"
            else
                echo "✗ Failed to remove gum via apt"
            fi
        elif command -v dnf &> /dev/null; then
            echo "Detected dnf package manager"
            if sudo dnf remove -y gum 2>/dev/null; then
                echo "✓ Successfully removed gum via dnf"
            else
                echo "✗ Failed to remove gum via dnf"
            fi
        elif command -v yum &> /dev/null; then
            echo "Detected yum package manager"
            if sudo yum remove -y gum 2>/dev/null; then
                echo "✓ Successfully removed gum via yum"
            else
                echo "✗ Failed to remove gum via yum"
            fi
        elif command -v brew &> /dev/null; then
            echo "Detected Homebrew package manager"
            if brew uninstall gum 2>/dev/null; then
                echo "✓ Successfully removed gum via Homebrew"
            else
                echo "✗ Failed to remove gum via Homebrew"
            fi
        elif command -v pacman &> /dev/null; then
            echo "Detected pacman package manager"
            if sudo pacman -R gum 2>/dev/null; then
                echo "✓ Successfully removed gum via pacman"
            else
                echo "✗ Failed to remove gum via pacman"
            fi
        elif command -v nix-env &> /dev/null; then
            echo "Detected Nix"
            if nix-env -e gum; then
                echo "✓ Successfully removed gum via Nix"
            fi
        elif command -v flox &> /dev/null; then
            echo "Detected Flox"
            if flox uninstall gum; then
                echo "✓ Successfully removed gum via Flox"
            fi
        else
            echo "⚠️  Could not detect package manager. gum may have been installed manually."
            echo "Please remove it manually according to how it was installed."
        fi
    else
        echo "✓ Keeping gum installed"
    fi
else
    echo "✓ gum is not installed, nothing to remove"
fi

echo ""
echo "Bimagic has been successfully uninstalled."
echo "Thank you for using Bimagic! ✨"