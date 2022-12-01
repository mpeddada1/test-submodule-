#!/bin/bash

set -ef

if [ ! -d "gax-java" ]; then
  echo "Create gax-java submodule if one does not exist"
  git submodule add --force $REPO
fi

cd gax-java
git checkout main

# Get GAX_VERSION
GAX_VERSION=$( ./gradlew -q :gax:properties | grep '^version: ' | cut -d' ' -f2 )
echo "Gax version is $GAX_VERSION"

if [ -z "$GRAALVM_VERSION" ]; then
  echo "Please provide GRAALVM_VERSION"
  exit 1
fi

# Checkout graalvm update branch
GRAALVM_BRANCH="${GRAALVM_VERSION}_update"
git status
git checkout -b "${GRAALVM_BRANCH}"

# Replace graal-sdk version in dependencies.properties
sed -i "s/graal-sdk.*/graal-sdk:${GRAALVM_VERSION}/g" dependencies.properties

# Replace graal-sdk version in parent pom.xml
replacement_command="s/<groupId>org.graalvm.sdk<\/groupId>\n        <artifactId>graal-sdk<\/artifactId>\n        <version>.*<\/version>/<groupId>org.graalvm.sdk<\/groupId>\n        <artifactId>graal-sdk<\/artifactId>\n        <version>${GRAALVM_VERSION}<\/version>/g"
perl -i -0pe "$replacement_command" pom.xml

# Push the dependency upgrade changes to branch on forked gax-java repo

git add pom.xml
git add dependencies.properties
git status

git commit -m "chore: prepare gax-java for graalvm (${GRAALVM_VERSION}) upgrade"
git push origin main




