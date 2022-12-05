#!/bin/bash

set -ef

if [ ! -d "java-shared-dependencies" ]; then
  echo "Create java-shared-config submodule if one does not exist"
  git submodule add --force $REPO
fi

if [ -z "$GRAALVM_VERSION" ]; then
  echo "Please provide GRAALVM_VERSION"
  exit 1
fi

# Go into the java-shared-dependencies submodule and checkout a branch
cd java-shared-dependencies
GRAALVM_BRANCH="${GRAALVM_VERSION}_update"
git checkout -b "${GRAALVM_BRANCH}"

SHARED_DEPENDENCIES_VERSION=$( mvn help:evaluate -Dexpression=project.version -q -DforceStdout )
echo "Java-shared-dependencies version is $SHARED_DEPENDENCIES_VERSION"

# If the current shared-dependencies version is a SNAPSHOT then this step is skipped.
if [[ ! $SHARED_DEPENDENCIES_VERSION = *"SNAPSHOT"* ]]; then
  VERSION_ARRAY=(${SHARED_DEPENDENCIES_VERSION//./ })
  PATCH_VERSION=${VERSION_ARRAY[2]}
  NEXT_PATCH_VERSION="$(($PATCH_VERSION + 1))"
  NEXT_SHARED_DEP_VERSION="${VERSION_ARRAY[0]}.${VERSION_ARRAY[1]}.${NEXT_PATCH_VERSION}"
  echo "$NEXT_SHARED_DEP_VERSION"
  grep -rl "${SHARED_DEPENDENCIES_VERSION}" | xargs sed -i "s/${SHARED_DEPENDENCIES_VERSION}/${NEXT_SHARED_DEP_VERSION}-SNAPSHOT/g"
fi

# Get the gax-java version
cd ..
cd gax-java
GAX_VERSION=$( ./gradlew -q :gax:properties | grep '^version: ' | cut -d' ' -f2 )
echo "Gax version is $GAX_VERSION"

# Get the java-shared-config version
cd ..
cd java-shared-config
SHARED_CONFIG_VERSION=$( mvn help:evaluate -Dexpression=project.version -q -DforceStdout )
echo "Java-shared-config version is $SHARED_CONFIG_VERSION"

cd ..
cd java-shared-dependencies
function update_gax_versions() {
  # replace version
  xmllint --shell pom.xml << EOF
  setns x=http://maven.apache.org/POM/4.0.0
  cd .//x:artifactId[text()="google-cloud-shared-config"]
  cd ../x:version
  set ${SHARED_CONFIG_VERSION}
  save pom.xml
EOF

  sed -i "s/<gax.version>.*<\/gax.version>/<gax.version>${GAX_VERSION}<\/gax.version>/g" pom.xml
}

# Update gax version in parent pom.xml
update_gax_versions

# Update gax version in parent first-party-dependencies/pom.xml
cd first-party-dependencies
update_gax_versions

# Update gax version in parent third-party-dependencies/pom.xml
cd ..
cd third-party-dependencies
update_gax_versions

# Go to java-shared-dependencies directory and commit changes
cd ..
git add pom.xml
git add first-party-dependencies/pom.xml
git add third-party-dependencies/pom.xml
git commit -m "chore: prepare shared-dependencies for (${GRAALVM_VERSION}) upgrade"
git push origin "${GRAALVM_BRANCH}"

echo "Before proceeding to the next step, create a draft PR from ${GRAALVM_BRANCH}"
echo "git submodule set-branch --branch ${GRAALVM_BRANCH} java-shared-dependencies && git add java-shared-dependencies && git add .gitmodules && git commit -m 'chore: add java-shared-dependencies submodule' && git push origin main"
