#!/bin/bash
# ==============================================================================
# Deskbox - Package Installation Script
# ==============================================================================
# Installs packages from a list file, verifying existence first
# Usage: ./install-deps.sh <package-list-file>
# ==============================================================================

set -e

PACKAGE_LIST="$1"

if [ ! -f "$PACKAGE_LIST" ]; then
    echo "Error: Package list file '$PACKAGE_LIST' not found."
    exit 1
fi

echo "Installing packages from $PACKAGE_LIST..."

apt-get update

# Filter comments and empty lines
grep -v '^#' "$PACKAGE_LIST" | grep -v '^$' > /tmp/packages-clean.txt

# Verify packages exist
echo "Verifying package existence..."
for pkg in $(cat /tmp/packages-clean.txt); do
    if apt-cache show "$pkg" >/dev/null 2>&1; then
        echo "$pkg" >> /tmp/packages-valid.txt
    else
        echo "Warning: Package $pkg not found, skipping..."
    fi
done

# Install valid packages
if [ -f /tmp/packages-valid.txt ]; then
    xargs -a /tmp/packages-valid.txt apt-get install -y --no-install-recommends
else
    echo "No valid packages found to install."
fi

# Cleanup
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

echo "Package installation completed."
