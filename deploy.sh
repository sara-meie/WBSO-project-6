#!/bin/bash

set -e

export ALAN_COMPILER_LOG=${ALAN_COMPILER_LOG:-warning} # default log level: warning

MODE="default"

if [[ $# -ge 1 && $1 == "migrate" ]]; then
    MODE="migrate"

    if [[ ! -e ".alan/deployed.alan" ]]; then
        echo "Error: unable to determine last deployed version." >&2
        exit 1
    fi
fi

./alan fetch
./alan build

compile_migration() {
    ".alan/dataenv/platform/project-compiler/tools/compiler-project" ".alan/dataenv/system-types/datastore/language-migration" -C "$1" "dist/$(basename $1).migration"
}

if [[ $MODE == "migrate" ]]; then
    MIGRATION_FOLDER=migrations/from_release
    if [[ ! -d ${MIGRATION_FOLDER} ]]; then
        .alan/dataenv/system-types/datastore/scripts/generate_migration.sh ${MIGRATION_FOLDER} systems/server/model.link
    fi
    cp .alan/deployed.alan ${MIGRATION_FOLDER}/from/application.alan
    compile_migration $MIGRATION_FOLDER
else
    MIGRATION_FOLDER=migrations/from_empty
    .alan/dataenv/system-types/datastore/scripts/generate_migration.sh ${MIGRATION_FOLDER} systems/server/model.link --strategy bootstrap
    compile_migration $MIGRATION_FOLDER
fi

./alan package ./dist/project.pkg "./deployments/${MODE}" ./dist/deploy.image

if mkdir .alan/deploy-lock &> /dev/null; then
    echo "Starting deployment to server, please wait..."
    if ./alan connect --direct "${ALAN_DEPLOY_HOST}" "${ALAN_DEPLOY_PORT}" "${ALAN_DEPLOY_KEY}" replace "${ALAN_CONTAINER_NAME}" "$(date +'%F %T')" ./dist/deploy.image; then
        rmdir .alan/deploy-lock
        cp models/model/application.alan .alan/deployed.alan
        echo "✅ DONE: application is available at: $ALAN_APP_URL"
    else
        rmdir .alan/deploy-lock
        echo "❌ ERROR: application could not be deployed." >&2
        exit 1
    fi
else
    echo "❌ ERROR: deployment already in progress." >&2
    exit 1
fi
