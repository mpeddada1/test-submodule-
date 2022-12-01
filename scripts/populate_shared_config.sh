#!/bin/bash

set -ef

if [ ! -d "java-shared-config" ]; then
  echo "Create java-shared-config submodule if one does not exist"
  git submodule add --force $REPO
fi

cd java-shared-config
git checkout main

if [ -z "${NATIVE_MAVEN_PLUGIN}" ]; then
  echo "Please specify the NATIVE_MAVEN_PLUGIN version"
  exit 1
fi

# Checkout a new branch.
PLUGIN_BRANCH="${NATIVE_MAVEN_PLUGIN}_update"
git status
git checkout -b "${PLUGIN_BRANCH}"

# Replace the native-maven-plugin version specified in the parent pom.xml with the one provided.
junit_platform_replacement="s/<artifactId>junit-platform-native<\/artifactId>\n          <version>.*<\/version>/<artifactId>junit-platform-native<\/artifactId>\n          <version>${NATIVE_MAVEN_PLUGIN}<\/version> <!-- update to latest version of native-maven-plugin -->\n/g"
native_maven_replacement="s/<artifactId>native-maven-plugin<\/artifactId>\n            <version>.*<\/version>/<artifactId>native-maven-plugin<\/artifactId>\n            <version>${NATIVE_MAVEN_PLUGIN}<\/version> <!-- update to latest version of native-maven-plugin -->\n/g"
perl -i -0pe "$junit_platform_replacement" pom.xml
perl -i -0pe "$native_maven_replacement" pom.xml

# Commit and push version upgrade changes
git add pom.xml
git commit -m "chore: upgrade native maven plugin in preparation for graalvm upgrade"
git push origin "${PLUGIN_BRANCH}"

echo "Before proceeding to the next step: In the github UI, create a draft PR from ${PLUGIN_BRANCH}"
echo "git submodule set-branch --branch ${PLUGIN_BRANCH} java-shared-config && git add java-shared-config && git add .gitmodules && git commit -m 'chore: add java-shared-config submodule' && git push origin main"


