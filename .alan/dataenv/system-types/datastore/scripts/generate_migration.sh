#!/bin/bash
set -e

if [[ $# -lt 2 ]]; then
	echo "Usage: 'migration directory' 'model.link' [--model 'model path'] [--strategy bootstrap|skip-interfaces]"
	echo "Example: migrations/from_zero systems/server/model.link --strategy bootstrap"
	exit
fi

SCRIPTDIR="$(cd "$(dirname "$0")"; pwd)"
LIBFILE=$(dirname "$2")/$(cat "$2")
MIGRDIR="$1"
shift 2

TRGFILE="models/model"
STRAFLAG=
STRATEGY=

while (($#)); do
	case $1 in
		--model)
			if [[ $# -lt 2 ]]; then
				echo "--model requires 'model path' argument"
				exit
			fi
			TRGFILE=$2
			shift 2
			;;

		--bootstrap)
			STRAFLAG="--strategy"
			STRATEGY="bootstrap"
			shift
			;;

		--strategy)
			if [[ $# -lt 2 ]]; then
				echo "--strategy requires an argument"
				exit
			fi
			STRAFLAG="--strategy"
			STRATEGY="$2"
			shift 2
			;;

		*)
			echo "unknown option $1"
			exit
			;;
	esac
done

echo "Creating migration layout at $MIGRDIR"

mkdir -p "$MIGRDIR/data"
mkdir -p "$MIGRDIR/from"
mkdir -p "$MIGRDIR/to"

echo "" > "$MIGRDIR/regexp.alan"
echo "../../../$TRGFILE/application.alan" > "$MIGRDIR/to/application.alan.link"

echo "$SCRIPTDIR/../tools/migration-generator" "$LIBFILE" $STRAFLAG $STRATEGY "$SCRIPTDIR/.temp.zip"
"$SCRIPTDIR/../tools/migration-generator" "$LIBFILE" $STRAFLAG $STRATEGY "$SCRIPTDIR/.temp.zip"
"$SCRIPTDIR/pretty-printer" "$SCRIPTDIR/../language-migration" --package "$SCRIPTDIR/.temp.zip" -C . --file "$MIGRDIR/migration.alan" -- migration.alan
if [[ "$STRATEGY" == "bootstrap" ]]; then
	"$SCRIPTDIR/pretty-printer" "$SCRIPTDIR/../language-migration" --package "$SCRIPTDIR/.temp.zip" -C . --file "$MIGRDIR/from/application.alan" -- from application.alan
fi

rm "$SCRIPTDIR/.temp.zip"
