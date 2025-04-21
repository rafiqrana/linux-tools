#!/bin/bash

# This script sets up a MATLAB desktop icon and application launcher for Linux.

# Script to create a MATLAB desktop icon and application launcher

ICON_DIR="$HOME/.local/share/icons"
DESKTOP_FILE="$HOME/.local/share/applications/matlab.desktop"
ICON_URL="https://raw.githubusercontent.com/rafiqrana/linux-tools/main/matlab/icon.png"

# Download MATLAB icon
wget  $ICON_URL -O $ICON_DIR/matlab.png

# Detect MATLAB installation directory
MATLAB_ROOT=$(which matlab | sed 's/\/bin\/matlab//')

if [ -z "$MATLAB_ROOT" ]; then
  echo "MATLAB not found. Please ensure MATLAB is installed and in your PATH."
  exit 1
fi

cat > "$DESKTOP_FILE" <<EOL
[Desktop Entry]
Name=MATLAB
Comment=Start MATLAB
Exec=$MATLAB_ROOT/bin/matlab -desktop
Icon=$ICON_DIR/matlab.png
Terminal=false
Type=Application
Categories=Development;Science;Education;
EOL

chmod +x "$DESKTOP_FILE"

# Update desktop database
# update-desktop-database "$HOME/.local/share/applications"

echo "MATLAB desktop icon and application launcher created successfully."
echo "You can find the icon in your applications menu."