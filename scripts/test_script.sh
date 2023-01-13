#!/bin/bash

SHARED_DEPENDENCIES_VERSION=$( mvn help:evaluate -Dexpression=project.version -q -DforceStdout | sed 's/\[[0-9;]*[JKmsu]//g' )
echo "Java-shared-dependencies version is $SHARED_DEPENDENCIES_VERSION"

# If the current shared-dependencies version is a SNAPSHOT then this step is skipped.
VERSION_ARRAY=(${SHARED_DEPENDENCIES_VERSION//./ })
PATCH_VERSION=${VERSION_ARRAY[2]}
NEXT_PATCH_VERSION="$((PATCH_VERSION + 1))"