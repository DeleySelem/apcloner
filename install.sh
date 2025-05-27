#!/bin/bash

# Installation script for APCloner

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root using sudo"
    exit 1
fi

# Configuration
INSTALL_DIR="/usr/share/apcloner"
BIN_LINK="/usr/bin/apcloner"
SCRIPT_NAME="apcloner.sh"

# Check if apcloner.sh exists in current directory
if [ ! -f "$(pwd)/$SCRIPT_NAME" ]; then
    echo "Error: $SCRIPT_NAME not found in current directory!"
    exit 1
fi

# Create installation directory
echo "Creating installation directory..."
mkdir -p "$INSTALL_DIR"

# Copy files
echo "Installing files..."
cp "$(pwd)/$SCRIPT_NAME" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

# Create binary link
echo "Creating system-wide shortcut..."
ln -sf "$INSTALL_DIR/$SCRIPT_NAME" "$BIN_LINK"

# Verify installation
if [ -f "$BIN_LINK" ] && [ -f "$INSTALL_DIR/$SCRIPT_NAME" ]; then
    echo -e "\nInstallation complete!"
    echo "You can now run the program with: sudo apcloner"
else
    echo -e "\nInstallation failed!"
    exit 1
fi

exit 0
