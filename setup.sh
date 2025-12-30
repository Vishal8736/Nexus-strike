#!/bin/bash

# Configuration
LOG_FILE="install_log.txt"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

############################################################
#                    BANNER DISPLAY                        #
############################################################

show_banner() {
    clear
    echo -e "${PURPLE}"
    echo "======================================================="
    echo "         AUTOMATED PENTESTING TOOLKIT SETUP            "
    echo "======================================================="
    echo -e "${RED}"
    # New Banner for NEXUS STRIKE
    echo "  _   _  _______   __  _    _  _____" 
    echo " | \ | || ____\ \ / / | |  | |/ ____|"
    echo " |  \| ||  _|  \ V /  | |  | | (___  "
    echo " | . \` || |___  > <   | |__| |\___ \ "
    echo " |_| \_||_____|/_/ \_\ \____/ ____) |"
    echo "                       |_____|"
    echo -e "${CYAN}"
    echo "     _____ _______ _____  _____ _  __ ______ "
    echo "    / ____|__   __|  __ \|_   _| |/ /|  ____|"
    echo "   | (___    | |  | |__) | | | | ' / | |__   "
    echo "    \___ \   | |  |  _  /  | | |  <  |  __|  "
    echo "    ____) |  | |  | | \ \ _| |_| . \ | |____ "
    echo "   |_____/   |_|  |_|  \_\_____|_|\_\|______|"
    echo -e "${NC}"
    echo "======================================================="
    echo -e "${YELLOW}       Created for: Vishal & Subhi      ${NC}"
    echo "======================================================="
    sleep 2
}

############################################################
#                 ENVIRONMENT CHECK                        #
############################################################

log() { echo -e "${BLUE}[*]${NC} $1"; }
success() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }

setup_environment() {
    log "Detecting Environment..."
    
    # Check if running in Termux
    if [ -d "/data/data/com.termux/files/home" ]; then
        warn "Termux Detected! Switching to 'pkg' manager..."
        PKG_MGR="pkg"
        SUDO=""
        # Termux specific repos
        pkg update -y && pkg upgrade -y
    else
        warn "Linux System Detected! Using 'apt'..."
        PKG_MGR="apt-get"
        SUDO="sudo"
        $SUDO apt-get update -y
    fi
}

############################################################
#                 INSTALL DEPENDENCIES                     #
############################################################

install_base() {
    log "Installing Base Dependencies (Git, Python, Go, Pip)..."
    
    if [ "$PKG_MGR" == "pkg" ]; then
        pkg install git python golang make curl wget -y
    else
        $SUDO apt-get install git python3 python3-pip golang curl wget -y
    fi
    success "Base dependencies installed."
}

############################################################
#             PROJECT DISCOVERY TOOLS (GO)                 #
############################################################

install_go_tools() {
    log "Installing ProjectDiscovery Tools (Katana, Naabu, Nuclei, HTTPX)..."
    
    # Setup Go Path
    export GOPATH=$HOME/go
    export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
    
    # Tools List
    go install -v github.com/projectdiscovery/katana/cmd/katana@latest
    go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest
    go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
    go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest
    go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
    
    success "Go tools installed."
}

############################################################
#                 GF & PATTERNS SETUP                      #
############################################################

install_gf() {
    log "Setting up GF (Grep Fuzzing) and Patterns..."
    go install -v github.com/tomnomnom/gf@latest
    
    # Create .gf directory
    mkdir -p ~/.gf
    
    # Clone Patterns
    if [ -d "Gf-Patterns" ]; then
        rm -rf Gf-Patterns
    fi
    git clone https://github.com/1ndianl33t/Gf-Patterns
    cp Gf-Patterns/*.json ~/.gf/
    rm -rf Gf-Patterns
    
    success "GF and Patterns configured."
}

############################################################
#              PYTHON TOOLS (SQLMap, Commix)               #
############################################################

install_python_tools() {
    log "Installing Exploitation Tools (SQLMap, Commix, SSTImap)..."
    
    # Install SQLMap & Commix via Pip (works best on Termux/Linux both)
    pip3 install sqlmap commix --upgrade
    
    # Install SSTImap
    cd $HOME
    if [ -d "SSTImap" ]; then
        warn "SSTImap already exists. Updating..."
        cd SSTImap && git pull
    else
        git clone https://github.com/vladko312/SSTImap
        cd SSTImap
    fi
    pip3 install -r requirements.txt
    cd $HOME
    
    success "Python tools installed."
}

############################################################
#                 FINAL CONFIGURATION                      #
############################################################

finalize() {
    log "Finalizing Setup..."
    
    # Add Go path to shell config permanently
    SHELL_CONFIG="$HOME/.bashrc"
    if [ -f "$HOME/.zshrc" ]; then
        SHELL_CONFIG="$HOME/.zshrc"
    fi
    
    if ! grep -q "export PATH=\$PATH:\$HOME/go/bin" "$SHELL_CONFIG"; then
        echo 'export PATH=$PATH:$HOME/go/bin' >> "$SHELL_CONFIG"
        echo 'export PATH=$PATH:$HOME/.local/bin' >> "$SHELL_CONFIG" # For pip tools
        warn "Added Go and Pip paths to $SHELL_CONFIG"
    fi
    
    log "Refreshing shell..."
    export PATH=$PATH:$HOME/go/bin:$HOME/.local/bin
}

############################################################
#                   MAIN EXECUTION                         #
############################################################

show_banner
setup_environment
install_base
install_go_tools
install_gf
install_python_tools
finalize

echo -e "${GREEN}"
echo "======================================================="
echo "       INSTALLATION COMPLETED SUCCESSFULLY!            "
echo "    NEXUS-STRIKE is ready for VISHAL & SUBHI ❤️        "
echo "======================================================="
echo -e "${NC}"
echo "Note: Please restart your terminal or run: source ~/.bashrc"
