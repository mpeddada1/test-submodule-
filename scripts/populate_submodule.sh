#!/bin/bash

set -ef

if [[ -z "$REPO" ]]; then
  echo "Please provide a repo url"
  exit 1
fi

if [[ $REPO = *"gax-java"* ]]; then
  source scripts/populate_gax.sh
elif [[ $REPO = *"java-shared-config"* ]]; then
  source scripts/populate_shared_config.sh
elif [[ $REPO = *"java-shared-dependencies"* ]]; then
  source scripts/populate_shared_dependencies.sh
else
  source scripts/populate_library.sh
fi