#!/bin/bash

# Only run once per session
if [ -z "$BADAPPLE_RAN" ]; then
  export BADAPPLE_RAN=1
  /usr/local/bin/badapple.sh
fi