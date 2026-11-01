#!/bin/sh
# Kindle 4: preserve original launch behavior, add live log rotation.
DEBUG=${DEBUG:-false}
[ "$DEBUG" = true ] && set -x
DIR=/mnt/us/dashboard
ENV_FILE="$DIR/local/env.sh"
LOG_DIR="$DIR/logs"

mkdir -p "$LOG_DIR" || exit 1
[ -f "$ENV_FILE" ] && . "$ENV_FILE"

if [ "$DEBUG" = true ]; then
    exec /bin/sh "$DIR/dash.sh"
fi

# Background process as in original start.sh. The logger owns the logfile.
( /bin/sh "$DIR/dash.sh" 2>&1 | /bin/sh "$DIR/log-writer.sh" ) </dev/null >/dev/null 2>"$LOG_DIR/start-error.log" &
