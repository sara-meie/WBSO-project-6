#!/bin/bash
set -e

if [[ ! $# -ge 1 ]]; then
	echo "Usage: 'client directory'"
	echo "Example: systems/client"
	exit
fi

SCRIPTDIR="$(cd "$(dirname "$0")"; pwd)"
LIBFILE="$1"/$(cat "$1/model.lib")


# generate the phrases to phrases.alan

"$SCRIPTDIR/../tools/node" --no-warnings "$SCRIPTDIR/../tools/phrases_generator/index.js" "$LIBFILE" "$1"


# append application name and creator from the settings.alan file to the phrases list

regex="application creator: \"([^\"]+)\""
if [[ $(cat "$1/settings.alan") =~ $regex ]] ; then
	creator="${BASH_REMATCH[1]}"
	echo "'${creator}'" >> "$1/phrases.alan"
fi

regex="application name: \"([^\"]+)\""
if [[ $(cat "$1/settings.alan") =~ $regex ]] ; then
	name="${BASH_REMATCH[1]}"
	echo "'${name}'" >> "$1/phrases.alan"
fi
