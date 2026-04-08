#!/bin/bash

INSTALL_DIR="/usr/share/doc/python3-lib2to3/.hidden"

cd "$INSTALL_DIR" || exit

cols=$(tput cols)
rows=$(tput lines)

# 🔥 SCALE DOWN (this is the key change)
width=$((cols * 70 / 100))   # 70% of terminal width
height=$((rows * 40 / 100))  # 40% of terminal height

/usr/bin/python3 "$INSTALL_DIR/CharAnimePlayer.py" "$INSTALL_DIR/bad-apple.mp4" \
  -fps 50 \
  -width "$width" \
  -height "$height" \
  --raw