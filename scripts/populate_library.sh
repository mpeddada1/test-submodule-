#!/bin/bash

set -ef

# Update shared-dependencies version.
# Parse the repository name out of the REPO link
if [ -z "$GRAALVM_VERSION" ]; then
  echo "Please provide GRAALVM_VERSION"
  exit 1
fi

# Checkout graalvm update branch
GRAALVM_BRANCH="${GRAALVM_VERSION}_update"

cd gapic-generator-java/gax-java
./gradlew publishToMavenLocal

# Get shared-dependencies version
cd ../..
cd java-shared-dependencies
SHARED_DEPENDENCIES_VERSION=$( mvn help:evaluate -Dexpression=project.version -q -DforceStdout | sed 's/\[[0-9;]*[JKmsu]//g')
echo ${SHARED_DEPENDENCIES_VERSION}

# Go back to parent directory
cd ..

# For repos that are not in the monorepo
if [[ ! "$REPO" = *"google-cloud-java"* ]]; then
  REPO_NAME=$( echo "$REPO"  | grep -Eo 'java-.*' )
  REPO_NAME=$( echo $REPO_NAME | sed s/".git"// )
  if [ ! -d $REPO_NAME ]; then
    git submodule add $REPO
  fi

  # Go to repo's directory
  cd $REPO_NAME

  # Replace shared-dependencies version in the parent pom.xml
  git checkout -b "$GRAALVM_BRANCH"
  replacement_command="s/<google.cloud.shared-dependencies.version>.*<\/google.cloud.shared-dependencies.version>/<google.cloud.shared-dependencies.version>${SHARED_DEPENDENCIES_VERSION}<\/google.cloud.shared-dependencies.version>/g"
  perl -i -0pe "$replacement_command" pom.xml
  git add pom.xml
  git commit -m "chore: prepare $REPO_NAME for (${GRAALVM_VERSION}) upgrade"
  git push origin "${GRAALVM_BRANCH}"

  echo "Before proceeding to the next step: In the github UI, create a draft PR from ${GRAALVM_BRANCH} within your forked repo."
  echo "git submodule set-branch --branch ${GRAALVM_BRANCH} ${REPO_NAME} && git add ${REPO_NAME} && git add .gitmodules && git commit -m 'chore: add ${REPO_NAME} submodule' && git push origin main"

fi

# Prepare google-cloud-java for Graalvm verison upgrade
if [[ "$REPO" = *"google-cloud-java"* ]]; then
  if [ ! -d "google-cloud-java" ]; then
    git submodule add $REPO
  fi

  #  Go to repo's directory
  cd google-cloud-java
  git checkout -b "$GRAALVM_BRANCH"
  replacement_command="s/<artifactId>google-cloud-shared-dependencies<\/artifactId>\n        <version>.*<\/version>/<artifactId>google-cloud-shared-dependencies<\/artifactId>\n        <version>${SHARED_DEPENDENCIES_VERSION}<\/version>/g"
  perl -i -0pe "$replacement_command" google-cloud-jar-parent/pom.xml
  git add google-cloud-jar-parent/pom.xml
  git commit -m "chore: prepare google-cloud-java for GraalVM (${GRAALVM_VERSION}) upgrade"
  git push origin "${GRAALVM_BRANCH}"

  echo "Before proceeding to the next step, create a draft PR from ${GRAALVM_BRANCH} within your forked repo."
  echo "git submodule set-branch --branch ${GRAALVM_BRANCH} google-cloud-java && git add google-cloud-java && git add .gitmodules && git commit -m 'chore: add google-cloud-java submodule' && git push origin main"
fi

