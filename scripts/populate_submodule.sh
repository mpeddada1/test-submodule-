#!/bin/bash

set -ef

if [[ $REPO = *"gax-java"* ]]; then
  source populate_gax.sh
fi
