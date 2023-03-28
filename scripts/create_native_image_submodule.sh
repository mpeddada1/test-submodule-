#!/bin/bash

set -eo pipefail

function modify_shared_config() {
  xmllint --shell pom.xml <<EOF
  setns x=http://maven.apache.org/POM/4.0.0
  cd .//x:artifactId[text()="google-cloud-shared-config"]
  cd ../x:version
  set ${SHARED_CONFIG_VERSION}
  save pom.xml
EOF
}

function modify_shared_dependencies() {
  xmllint --shell pom.xml <<EOF
  setns x=http://maven.apache.org/POM/4.0.0
  cd .//x:artifactId[text()="google-cloud-shared-dependencies"]
  cd ../x:version
  set ${SHARED_DEPS_VERSION}
  save pom.xml
EOF
}

## Get the directory of the build script
scriptDir=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
## cd to the parent directory, i.e. the root of the git repo
cd "${scriptDir}/.."

pwd

# TODO(mpeddada): Undo this change when this script is ready. This will be passed as an argument.
GRAALVM_VERSION=22.2.0
NATIVE_MAVEN_PLUGIN=0.9.21

# Use GCP Maven Mirror
mkdir -p "${HOME}/.m2"
cp settings.xml "${HOME}/.m2"

### Round 1: Add gapic-generator-java and update graal-sdk version in GAX.
# If gapic-generator-java is not present, clone it and add it to submodule project
if [ ! -d "gapic-generator-java" ]; then
  echo "Create gapic-generator-java submodule if one does not exist"
  git submodule add --force https://github.com/googleapis/gapic-generator-java.git
fi

# Modify graal-sdk version in GAX
pushd gapic-generator-java/gax-java
xmllint --shell pom.xml <<EOF
setns x=http://maven.apache.org/POM/4.0.0
cd .//x:artifactId[text()="graal-sdk"]
cd ../x:version
set ${GRAALVM_VERSION}
save pom.xml
EOF

# Get java-shared-dependencies version
popd
pushd gapic-generator-java
SHARED_DEPS_VERSION=$(sed -e 's/xmlns=".*"//' java-shared-dependencies/pom.xml | xmllint --xpath '/project/version/text()' -)
echo $SHARED_DEPS_VERSION

# Publish this repo's modules to local maven to make them available for downstream libraries
mvn -B -ntp install --projects '!gapic-generator-java' \
  -Dcheckstyle.skip -Dfmt.skip -DskipTests -Denforcer.skip

git diff

#git checkout -b graalvm-submodule-test2
#git add gax-java/pom.xml
#git commit -m "chore: update graalvm-sdk's version in GAX for testing"
#git push origin graalvm-submodule-test2
popd

### Round 2: Add java-shared-config if not present and update native-maven-plugin's version
if [ ! -d "java-shared-config" ]; then
  echo "Create java-shared-config submodule if one does not exist"
  git submodule add --force https://github.com/googleapis/java-shared-config.git
fi

# Modify junit-platform-native and native-maven-plugin
pushd java-shared-config
ls
pwd
SHARED_CONFIG_VERSION=$(sed -e 's/xmlns=".*"//' pom.xml | xmllint --xpath '/project/version/text()' -)

xmllint --shell pom.xml <<EOF
setns x=http://maven.apache.org/POM/4.0.0
cd .//x:artifactId[text()="junit-platform-native"]
cd ../x:version
set ${NATIVE_MAVEN_PLUGIN}
save pom.xml
EOF

xmllint --shell pom.xml <<EOF
setns x=http://maven.apache.org/POM/4.0.0
cd .//x:artifactId[text()="native-maven-plugin"]
cd ../x:version
set ${NATIVE_MAVEN_PLUGIN}
save pom.xml
EOF

echo "Modified native-maven-plugin in shared-config"
git diff
mvn install

# Create branch on github
git checkout -b graalvm-submodule-test2
git add pom.xml
git commit -m "chore: update native-maven-plugin's version in java-shared-config for testing"
git push origin graalvm-submodule-test2

popd

### Round 3: Add java-pubsub if not present and update versions of shared-dependencies and java-shared-config.
if [ ! -d "java-pubsub" ]; then
  echo "Create java-pubsub submodule if one does not exist"
  git submodule add --force https://github.com/googleapis/java-pubsub.git
fi

# Update shared-config and shared-dependencies version
pushd java-pubsub
modify_shared_config
modify_shared_dependencies
echo "Modified shared-config and shared-dependencies versions in java-pubsub"
git diff

git checkout -b graalvm-submodule-test2
git add pom.xml
git commit -m "chore: update shared-dependencies version for testing"
git push origin graalvm-submodule-test2

popd

### Round 4: Add java-bigquery if not present and update versions of shared-dependencies and java-shared-config.
if [ ! -d "java-bigquery" ]; then
  echo "Create java-bigquery submodule if one does not exist"
  git submodule add --force https://github.com/googleapis/java-bigquery.git
fi

# Update shared-config and shared-dependencies version
pushd java-bigquery
modify_shared_config
modify_shared_dependencies
echo "Modified shared-config and shared-dependencies versions in java-bigquery"
git diff

git checkout -b graalvm-submodule-test2
git add pom.xml
git commit -m "chore: update shared-dependencies version for testing"
git push origin graalvm-submodule-test2
popd

### Round 5: Add java-bigtable if not present and update versions of shared-dependencies and java-shared-config.
#if [ ! -d "java-bigtable" ]; then
#  echo "Create java-bigtable submodule if one does not exist"
#  git submodule add --force https://github.com/googleapis/java-bigtable.git
#fi
#
## Update shared-config and shared-dependencies version
#pushd java-bigtable
#modify_shared_config
#modify_shared_dependencies
#echo "Modified shared-config and shared-dependencies versions in java-bigtable"
#git diff
#popd


git add gapic-generator-java
git add java-shared-config
git add java-pubsub
git add java-bigquery
git commit -m "chore: populate the submodule project"
git push origin main