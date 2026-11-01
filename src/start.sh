#!/usr/bin/env sh
# Kindle 4: original startup behavior with continuous log rotation.
DEBUG=${DEBUG:-false}
[ "$DEBUG" = true ] && set -x
DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)" || exit 1
ENV_FILE="$DIR/local/env.sh"
[ -f "$ENV_FILE" ] && . "$ENV_FILE"

if [ "$DEBUG" = true ]; then
    exec /bin/sh "$DIR/dash.sh"
fi

mkdir -p "$DIR/logs" || exit 1
# Keep producer's stdout/stderr on a pipe, not on a permanently opened log.
( /bin/sh "$DIR/dash.sh" 2>&1 | /bin/sh "$DIR/log-writer.sh" ) </dev/null >/dev/null 2>&1 &
