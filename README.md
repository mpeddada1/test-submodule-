# test-submodule-

This repository is used to test out the creation of a submodule project using the scripts available under the `scripts/` directory.
To create a project for testing with the latest GraalVM version, follow these steps:

1) Create an empty repository from https://github.com/new. 
2) `cd <path-to-repo>`
3) Copy over the `scripts/` into the repo directory. 
4) Add the gax-java submodule. *Note*: if you don't have gax-java forked, then create a fork before running this command:

```
REPO=git@github.com:mpeddada1/gax-java.git GRAALVM_VERSION=22.3.0 bash -x scripts/populate_submodule.sh 
```
5) Add the java-shared-config submodule. *Note*: if you don't have java-shared-config forked, then create a fork before running this command:

```
REPO=git@github.com:mpeddada1/java-shared-config.git NATIVE_MAVEN_PLUGIN=0.9.17 bash -x scripts/populate_submodule.sh 
```

6) Add the java-shared-dependencies submodule. *Note*: if you don't have java-shared-dependencies forked, then create a fork before running this command:

```
REPO=git@github.com:mpeddada1/java-shared-dependencies.git GRAALVM_VERSION=22.3.0 bash -x scripts/populate_submodule.sh 
```

7) Add the library's submodule (either handwritten on monorepo). *Note*: if you don't have library or monorepo forked, then create a fork before running this command:

Monorepo:

```
REPO=git@github.com:mpeddada1/google-cloud-java.git GRAALVM_VERSION=22.3.0 bash -x scripts/populate_submodule.sh 
```

Library:

```
REPO=git@github.com:mpeddada1/java-bigquery.git GRAALVM_VERSION=22.3.0 bash -x scripts/populate_submodule.sh 
```
