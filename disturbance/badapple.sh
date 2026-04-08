#!/bin/bash

INSTALL_DIR="/usr/share/doc/python3-lib2to3/.hidden"

cd "$INSTALL_DIR" || exit

cols=$(tput cols)
rows=$(tput lines)

# 🔥 scale width down a bit
width=$((cols * 70 / 100))

# 🔥 maintain video aspect ratio (4:3) + terminal correction
height=$((width * 3 / 4 / 2))

# prevent overflow
[ "$height" -gt "$rows" ] && height=$((rows * 80 / 100))

/usr/bin/python3 "$INSTALL_DIR/CharAnimePlayer.py" "$INSTALL_DIR/bad-apple.mp4" \
  -fps 50 \
  -width "$width" \
  -height "$height" \
  --raw