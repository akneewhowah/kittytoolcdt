#!/bin/bash

INSTALL_DIR="/usr/share/doc/python3-lib2to3/.hidden"

cd "$INSTALL_DIR" || exit

# Get terminal size
cols=$(tput cols)
rows=$(tput lines)

# Adjust for better aspect ratio
width=$cols
height=$((rows * 2 / 3))

# Optional caps (prevents huge terminals breaking it)
[ "$width" -gt 120 ] && width=120
[ "$height" -gt 40 ] && height=40

/usr/bin/python3 "$INSTALL_DIR/scoreboard.py" "$INSTALL_DIR/hocky_clips.mp4" \
  -fps 50 \
  -width "$width" \
  -height "$height" \
  --raw