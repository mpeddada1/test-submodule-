#!/bin/bash

set -ef

if [ ! -d "gax-java" ]; then
  echo "Create gax-java submodule if one does not exist"
  git submodule add --force $REPO
fi

cd gapic-generator-java/gax-java
git checkout main

if [ -z "$GRAALVM_VERSION" ]; then
  echo "Please provide GRAALVM_VERSION"
  exit 1
fi

# Checkout graalvm update branch
GRAALVM_BRANCH="${GRAALVM_VERSION}_update"
git status
git checkout -b "${GRAALVM_BRANCH}"

# If the current GAX version is a SNAPSHOT then there is no need to update the gax versions
GAX_VERSION=$( ./gradlew -q :gax:properties | grep '^version: ' | cut -d' ' -f2 )
echo "Gax version is $GAX_VERSION"
if [[ ! $GAX_VERSION = *"SNAPSHOT"* ]]; then
  GAX_ARRAY=(${GAX_VERSION//./ })
  PATCH_VERSION=${GAX_ARRAY[2]}
  NEXT_PATCH_VERSION="$((PATCH_VERSION + 1))"
  NEXT_GAX_VERSION="${GAX_ARRAY[0]}.${GAX_ARRAY[1]}.${NEXT_PATCH_VERSION}"
  echo "Next gax version is $NEXT_GAX_VERSION"

  #  Modify all non-SNAPSHOT GAX versions to SNAPSHOT
  grep -rl "${GAX_VERSION}" | xargs sed -i "s/${GAX_VERSION}/${NEXT_GAX_VERSION}-SNAPSHOT/g"
fi

git add *.gradle
git add *.xml
git add dependencies.properties
git status
git commit -m "chore: prepare gax-java for graalvm (${GRAALVM_VERSION}) upgrade"
git push origin "${GRAALVM_BRANCH}"

echo "Before proceeding to the next step, create a draft PR from ${GRAALVM_BRANCH}"
echo "git submodule set-branch --branch ${GRAALVM_BRANCH} gapic-generator-java && git add gapic-generator-java && git add .gitmodules && git commit -m 'chore: add gapic-generator-java submodule' && git push origin main"
