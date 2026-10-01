#!/bin/bash
# haven: the CLI's old name inside the workspace, installed as /usr/local/bin/haven.
# It prints one notice on stderr and then runs bulkhead with the same arguments.
# BULKHEAD_RENAME_NOTICE=0 silences the notice; the host CLI sets it when it calls in.
[ "${BULKHEAD_RENAME_NOTICE:-1}" = 0 ] || echo "This command is now 'bulkhead' (short: 'bh'). 'haven' still works." >&2
exec "$(dirname "$0")/bulkhead" "$@"
