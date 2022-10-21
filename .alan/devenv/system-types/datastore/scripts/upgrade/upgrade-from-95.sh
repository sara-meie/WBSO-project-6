#!/bin/bash
set -e

if [[ $# -lt 1 ]]; then
	echo "Usage: 'path to datastore system'"
	echo "Example: systems/server"
	exit
fi

SCRIPTDIR="$(cd "$(dirname "$0")"; pwd)"

"$SCRIPTDIR/syntax-converter" "$SCRIPTDIR/language" "$SCRIPTDIR/syntax-from-95" -C "${1}"
"$SCRIPTDIR/pretty-printer" "$SCRIPTDIR/../../language" --allow-unresolved -C "${1}"
