#!/bin/bash

# Pop!_OS Fast Setup Script
# Run with: bash setup-popos.sh

set -e  # Exit on error

echo "================================"
echo "Pop!_OS Fast Setup Script"
echo "================================"
echo ""

# Update package list
echo "[1/8] Updating package lists..."
sudo apt update

# Install build dependencies for Rust compilation
echo "[2/8] Installing build dependencies..."
sudo apt install -y build-essential pkg-config libssl-dev

# Install zsh
echo "[3/8] Installing zsh..."
sudo apt install -y zsh

# Install Oh My Zsh
echo "[4/8] Installing Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "Oh My Zsh already installed, skipping..."
fi

# Install zsh-syntax-highlighting
echo "[4.5/8] Installing zsh-syntax-highlighting..."
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
else
    echo "zsh-syntax-highlighting already installed, skipping..."
fi

# Enable syntax highlighting in .zshrc
if ! grep -q "zsh-syntax-highlighting" "$HOME/.zshrc"; then
    sed -i 's/plugins=(git)/plugins=(git zsh-syntax-highlighting)/' "$HOME/.zshrc"
fi

# Install JetBrains Mono Nerd Font
echo "[5/8] Installing JetBrains Mono Nerd Font..."
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

if [ ! -f "$FONT_DIR/JetBrainsMonoNerdFont-Regular.ttf" ]; then
    cd /tmp
    curl -fLO https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
    unzip -o JetBrainsMono.zip -d "$FONT_DIR"
    rm JetBrainsMono.zip
    fc-cache -fv
    echo "JetBrains Mono Nerd Font installed!"
else
    echo "JetBrains Mono Nerd Font already installed, skipping..."
fi

# Install Gogh Cai Theme
echo "[5/8] Installing Gogh Cai terminal theme..."
sudo apt install -y dconf-cli uuid-runtime

# Download Gogh apply script and Cai theme
cd /tmp
wget -q https://github.com/Gogh-Co/Gogh/raw/master/apply-colors.sh
wget -q https://github.com/Gogh-Co/Gogh/raw/master/installs/cai.sh

# Apply Cai theme non-interactively
TERMINAL=gnome-terminal GOGH_NONINTERACTIVE=1 GOGH_USE_NEW_THEME=1 bash ./cai.sh

# Cleanup
rm -f apply-colors.sh cai.sh
cd - > /dev/null

echo "Cai theme installed!"

# Install Starship
echo "[6/8] Installing Starship..."
if ! command -v starship &> /dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
else
    echo "Starship already installed, skipping..."
fi

# Download Starship config
echo "[6.5/8] Downloading Starship and Git configurations..."
mkdir -p "$HOME/.config"
wget -q https://raw.githubusercontent.com/Badr-1/configs/main/starship.toml -O "$HOME/.config/starship.toml"
echo "Starship config downloaded to ~/.config/starship.toml"

# Download gitconfig
wget -q https://raw.githubusercontent.com/Badr-1/configs/main/.gitconfig -O "$HOME/.gitconfig"
echo "Git config downloaded to ~/.gitconfig"

# Add Starship to .zshrc if not already present
if ! grep -q "starship init zsh" "$HOME/.zshrc"; then
    echo 'eval "$(starship init zsh)"' >> "$HOME/.zshrc"
fi

# Install Rust and Cargo
echo "[7/8] Installing Rust and Cargo..."
if ! command -v cargo &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
else
    echo "Cargo already installed, skipping..."
fi

# Ensure cargo is in PATH for this script
export PATH="$HOME/.cargo/bin:$PATH"

# Install Rust CLI tools
echo "[8/8] Installing Rust alternatives..."

# Install cargo-update for Topgrade
echo "  - Installing cargo-update..."
cargo install cargo-update

# Install bat (batcat alternative)
echo "  - Installing bat..."
cargo install bat

# Install lsd (ls alternative)
echo "  - Installing lsd..."
cargo install lsd

# Install Topgrade
echo "  - Installing Topgrade..."
cargo install topgrade

# Install additional applications
echo ""
echo "[9/9] Installing additional applications..."

# Update Git to latest version
echo "  - Adding Git PPA and updating to latest version..."
sudo add-apt-repository -y ppa:git-core/ppa
sudo apt update
sudo apt install -y git

# Install Docker
echo "  - Installing Docker..."
# Add Docker's official GPG key
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources
sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add current user to docker group (enables running docker without sudo)
sudo usermod -aG docker $USER
newgrp docker 2>/dev/null || true
echo "Docker installed! User added to docker group."

# Install Docker Desktop
echo "  - Installing Docker Desktop..."
cd /tmp
wget -q https://desktop.docker.com/linux/main/amd64/docker-desktop-amd64.deb
sudo apt install -y ./docker-desktop-amd64.deb
rm docker-desktop-amd64.deb
cd - > /dev/null
echo "Docker Desktop installed!"
echo "NOTE: You'll need to log out and back in for docker group membership to fully take effect."

# Install APT packages
echo "  - Installing Xournalpp, VS Code, and Vim..."
sudo apt install -y xournalpp code vim

# Install Flatpak packages
echo "  - Installing OBS Studio and plugins via Flatpak..."
flatpak install -y flathub com.obsproject.Studio
flatpak install -y flathub com.obsproject.Studio.Plugin.AdvancedMasks
flatpak install -y flathub com.obsproject.Studio.Plugin.MoveTransition

echo "Additional applications installed!"

# Setup aliases
echo ""
echo "Setting up aliases..."

# Create or update aliases in .zshrc
ALIAS_BLOCK="
# Rust CLI tool aliases
alias cat='bat'
alias ls='lsd'
"

if ! grep -q "# Rust CLI tool aliases" "$HOME/.zshrc"; then
    echo "$ALIAS_BLOCK" >> "$HOME/.zshrc"
    echo "Aliases added to .zshrc"
else
    echo "Aliases already present in .zshrc"
fi

# Change default shell to zsh
echo ""
echo "Changing default shell to zsh..."
if [ "$SHELL" != "$(which zsh)" ]; then
    chsh -s $(which zsh)
    echo "Default shell changed to zsh. Please log out and log back in for changes to take effect."
else
    echo "Default shell is already zsh"
fi

echo ""
echo "================================"
echo "Setup Complete!"
echo "================================"
echo ""
echo "Installed:"
echo "  ✓ zsh with Oh My Zsh"
echo "  ✓ zsh-syntax-highlighting"
echo "  ✓ JetBrains Mono Nerd Font"
echo "  ✓ Gogh Cai terminal theme"
echo "  ✓ Starship prompt (with custom config)"
echo "  ✓ Git (latest version) with custom configuration"
echo "  ✓ Docker Engine (with Compose, BuildX plugins)"
echo "  ✓ Docker Desktop"
echo "  ✓ Rust & Cargo"
echo "  ✓ bat (aliased to 'cat')"
echo "  ✓ lsd (aliased to 'ls')"
echo "  ✓ cargo-update"
echo "  ✓ Topgrade"
echo "  ✓ Xournalpp"
echo "  ✓ VS Code"
echo "  ✓ Vim"
echo "  ✓ OBS Studio (with AdvancedMasks & MoveTransition plugins)"
echo ""
echo "Please run: source ~/.zshrc"
echo "Or log out and log back in to use zsh as your default shell."
echo ""
echo "IMPORTANT: To use Docker without sudo, you MUST log out and log back in!"
echo ""
