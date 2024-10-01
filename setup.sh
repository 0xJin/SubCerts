#!/bin/bash

# Function to install required dependencies
install_dependencies() {
    echo "[*] Installing necessary dependencies..."

    # Update package list
    sudo apt update

    # Install jq and curl if not already installed
    sudo apt install -y jq curl

    # Install Go (Golang) if not installed
    if ! command -v go &> /dev/null; then
        echo "[*] Installing Go..."
        sudo apt install -y golang
    else
        echo "[*] Go is already installed."
    fi

    # Install httpx if not already installed
    if ! command -v httpx &> /dev/null; then
        echo "[*] Installing httpx..."
        go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
        # Ensure the Go bin path is added to the system PATH
        export PATH=$PATH:/root/go/bin
    else
        echo "[*] httpx is already installed."
    fi
}

# Run the installation function
install_dependencies

echo "[*] Setup completed successfully!"
