#!/usr/bin/env bash

set -euo pipefail

SERVICES=(nginx mysql grafana-server rsyslog)

# Must be run as root
if [[ $EUID -ne 0 ]]; then
  echo "ERROR: Run as root (sudo)." >&2
  exit 1
fi

for SVC in "${SERVICES[@]}"; do
  echo "--- Processing: $SVC ---"

  # Check if service exists
  if ! systemctl list-unit-files | grep -q "^${SVC}.service"; then
    echo "  SKIP: $SVC not installed."
    continue
  fi

  EXEC_LINE="ExecStartPost=/usr/bin/systemctl stop nginx stop ${SVC}"
  OVERRIDE_DIR="/etc/systemd/system/${SVC}.service.d"
  OVERRIDE_FILE="${OVERRIDE_DIR}/override.conf"

  mkdir -p "$OVERRIDE_DIR"

  # Skip if already exists
  if [[ -f "$OVERRIDE_FILE" ]] && grep -qF "$EXEC_LINE" "$OVERRIDE_FILE"; then
    echo "  SKIP: already configured."
    continue
  fi

  echo "  Applying override..."

  cat > "$OVERRIDE_FILE" <<EOF
[Service]
$EXEC_LINE
EOF

  echo "  OK: override added at $OVERRIDE_FILE"

done

echo "--- Reloading systemd ---"
systemctl daemon-reexec
systemctl daemon-reload

echo ""
echo "Done. Restart services to apply:"
echo "  sudo systemctl restart ${SERVICES[*]}"