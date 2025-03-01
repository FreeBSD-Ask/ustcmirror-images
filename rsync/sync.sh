#!/bin/bash

## EXPORTED IN entry.sh
#TO=
#LOGDIR=
#LOGFILE=

set -eu
[[ $DEBUG = true ]] && set -x

BIND_ADDRESS=${BIND_ADDRESS:-''}

RSYNC_USER=${RSYNC_USER:-''}
RSYNC_BW=${RSYNC_BW:-0}
RSYNC_EXCLUDE=${RSYNC_EXCLUDE:-' --exclude .~tmp~/'}
RSYNC_FILTER=${RSYNC_FILTER:-}
RSYNC_MAXDELETE=${RSYNC_MAXDELETE:-4000}
RSYNC_TIMEOUT="${RSYNC_TIMEOUT:-14400}"
RSYNC_BLKSIZE="${RSYNC_BLKSIZE:-8192}"
RSYNC_EXTRA=${RSYNC_EXTRA:-''}
RSYNC_RSH=${RSYNC_RSH:-''}
RSYNC_DELAY_UPDATES="${RSYNC_DELAY_UPDATES:-true}"
RSYNC_SPARSE="${RSYNC_SPARSE:-true}"
RSYNC_DELETE_DELAY="${RSYNC_DELETE_DELAY:-true}"
RSYNC_DELETE_EXCLUDED="${RSYNC_DELETE_EXCLUDED:-true}"

opts="-pPrltvH --partial-dir=.rsync-partial --timeout ${RSYNC_TIMEOUT} --safe-links"

[[ -n $RSYNC_USER ]] && RSYNC_HOST="$RSYNC_USER@$RSYNC_HOST"

[[ $RSYNC_DELETE_EXCLUDED = true ]] && opts+=' --delete-excluded'
[[ $RSYNC_DELETE_DELAY = true ]] && opts+=' --delete-delay' || opts+=' --delete'
[[ $RSYNC_DELAY_UPDATES = true ]] && opts+=' --delay-updates'
[[ $RSYNC_SPARSE = true ]] && opts+=' --sparse'
[[ $RSYNC_BLKSIZE -ne 0 ]] && opts+=" --block-size ${RSYNC_BLKSIZE}"

if [[ -n $BIND_ADDRESS ]]; then
    if [[ $BIND_ADDRESS =~ .*: ]]; then
        opts+=" -6 --address $BIND_ADDRESS"
    else
        opts+=" -4 --address $BIND_ADDRESS"
    fi
fi

filter_file=/tmp/rsync-filter.txt
echo '- .~tmp~/' > "$filter_file"
if [ -n "$RSYNC_FILTER" ]; then
  echo "$RSYNC_FILTER" >> "$filter_file"
fi

if [[ -n $RSYNC_RSH ]]; then
  RSYNC_URL="$RSYNC_HOST:$RSYNC_PATH"
else
  RSYNC_URL="rsync://$RSYNC_HOST/$RSYNC_PATH"
fi

exec rsync $RSYNC_EXCLUDE --filter="merge $filter_file" --bwlimit "$RSYNC_BW" --max-delete "$RSYNC_MAXDELETE" $opts $RSYNC_EXTRA "$RSYNC_URL" "$TO"
