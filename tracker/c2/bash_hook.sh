#!/bin/bash

# Create the named pipe if it doesn't exist
if [ ! -p "/tmp/bash_logger_pipe" ]; then
    mkfifo /tmp/bash_logger_pipe
fi

# Function to log commands
log_command() {
    if [ -n "$BASH_COMMAND" ]; then
        echo "$BASH_COMMAND" > /tmp/bash_logger_pipe
    fi
}

# Trap DEBUG to execute before each command
trap 'log_command' DEBUG

# Start the logger in background if not already running
if ! pgrep -f "logger" > /dev/null; then
    nohup /path/to/logger > /dev/null 2>&1 &
fi