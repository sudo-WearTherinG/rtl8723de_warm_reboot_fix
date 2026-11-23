
#!/bin/bash
set -e

SERVICE="rtl8723de-unload.service"
SERVICE_FILE="/etc/systemd/system/$SERVICE"

echo "Installing RTL8723DE shutdown driver unload service..."

# Create systemd service
sudo tee "$SERVICE_FILE" > /dev/null <<'EOF'
[Unit]
Description=Quiesce RTL8723DE combo device before shutdown
Before=NetworkManager.service shutdown.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/true

# Unload Bluetooth driver
ExecStop=-/usr/bin/modprobe -r btusb

# Verify Bluetooth driver unload
ExecStop=/bin/bash -c 'if /usr/bin/lsmod | /usr/bin/grep -q "^btusb "; then echo "btusb STILL LOADED"; else echo "btusb successfully unloaded"; fi | /usr/bin/systemd-cat -t rtl8723de-unload'

# Unload Wi-Fi driver
ExecStop=-/usr/bin/modprobe -r rtw88_8723de

# Verify Wi-Fi driver unload
ExecStop=/bin/bash -c 'if /usr/bin/lsmod | /usr/bin/grep -q "^rtw88_8723de "; then echo "rtw88_8723de STILL LOADED"; else echo "rtw88_8723de successfully unloaded"; fi | /usr/bin/systemd-cat -t rtl8723de-unload'

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
sudo systemctl daemon-reload

# Enable service
sudo systemctl enable "$SERVICE"

echo
echo "Installation completed."
echo

# Verify
sudo systemctl status "$SERVICE" --no-pager

echo
echo "The drivers will be unloaded during shutdown."
echo "Their unload status will be recorded in the journal."
echo "They should initialize normally on the next boot."

