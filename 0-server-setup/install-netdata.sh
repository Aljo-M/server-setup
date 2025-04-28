#!/bin/bash

# Note: Run this script as root or with sudo privileges.

# --- Install Netdata (Skip if Already Installed) ---
if command -v netdata &> /dev/null; then
    echo "=== Netdata is already installed ==="
else
    echo "=== Installing Netdata ==="
    if ! sudo $PM install -y netdata; then
        handle_error "Failed to install Netdata"
    fi
    echo "=== Netdata installed successfully ==="
fi

# --- Configure Netdata ---
CONFIG_FILE="/etc/netdata/netdata.conf"
echo "=== Checking Netdata configuration ==="
if [ -f "$CONFIG_FILE" ]; then
    if grep -q "bind to = 0.0.0.0" "$CONFIG_FILE"; then
        echo "=== Netdata is already configured to bind to 0.0.0.0 ==="
    else
        echo "=== Configuring Netdata to bind to 0.0.0.0 ==="
        # Backup the original configuration
        sudo cp "$CONFIG_FILE" "$CONFIG_FILE.bak"
        sudo sed -i 's/bind to = 127.0.0.1/bind to = 0.0.0.0/g' "$CONFIG_FILE"
        # Verify the configuration change
        if grep -q "bind to = 0.0.0.0" "$CONFIG_FILE"; then
            echo "=== Configuration updated successfully ==="
        else
            echo "=== WARNING: Failed to update configuration ==="
        fi
    fi
else
    echo "=== WARNING: Netdata configuration file not found at $CONFIG_FILE ==="
    echo "=== Please configure manually. Refer to: https://learn.netdata.cloud/docs/agent/packaging/installer ==="
fi

# --- Restart and Enable Netdata Service ---
echo "=== Restarting and enabling Netdata service ==="
if ! sudo systemctl restart netdata; then
    echo "=== ERROR: Failed to restart Netdata service ==="
fi
if ! sudo systemctl enable netdata; then
    echo "=== ERROR: Failed to enable Netdata service ==="
fi

# --- Verify Service Status ---
echo "=== Verifying Netdata service status ==="
if sudo systemctl is-active --quiet netdata; then
    echo "=== Netdata service is active ==="
else
    handle_error "Netdata service is not active"
fi

# --- Completion Message with Access Info ---
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "=== Netdata installation complete. Access it at http://$SERVER_IP:19999 ==="