#!/bin/bash

set -ef

if [[ $REPO = *"gax-java"* ]]; then
  source scripts/populate_gax.sh
fi

if [[ $REPO = *"java-shared-config"* ]]; then
  source scripts/populate_shared_config.sh
fi