#!/bin/bash

set -ef

if [[ -z "$REPO" ]]; then
  echo "Please provide the url for the repo that needs to be added to the submodule project."
  exit 1
fi

pwd
if [[ $REPO = *"gapic-generator-java"* ]]; then
  source $(dirname "$0")/populate_gax.sh
elif [[ $REPO = *"java-shared-config"* ]]; then
  source $(dirname "$0")/populate_shared_config.sh
elif [[ $REPO = *"java-shared-dependencies"* ]]; then
  source $(dirname "$0")/populate_shared_dependencies.sh
elif [[ $REPO = *"google-cloud-java"* ]] || [[ $REPO = *"java-"* ]]; then
  source $(dirname "$0")/populate_library.sh
else
  echo "Unable to determine the repository specified. Please verify the value of the provided REPO env variable."
  exit 1
fi