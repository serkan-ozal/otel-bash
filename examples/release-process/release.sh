#!/bin/bash

. ../../otel_bash.sh

# or get the latest version of the "otel-bash" from remote
# . /dev/stdin <<< "$(curl -s https://raw.githubusercontent.com/serkan-ozal/otel-bash/master/otel_bash.sh)"

# or if your bash supports process substitution (version "4.x")
# . <(curl -s https://raw.githubusercontent.com/serkan-ozal/otel-bash/master/otel_bash.sh)

# or get specific version (v<version>) of the "otel-bash" from remote
# for example, "v0.0.1" for the "0.0.1" version of the "otel-bash"
# . /dev/stdin <<< "$(curl -s https://raw.githubusercontent.com/serkan-ozal/otel-bash/v0.0.1/otel_bash.sh)"

# or if your bash supports process substitution (version "4.x")
# . <(curl -s https://raw.githubusercontent.com/serkan-ozal/otel-bash/v0.0.1/otel_bash.sh)

function run_build {
    echo "[RELEASE] Building ..."
    ./build.sh
    echo "[RELEASE] Build completed"
}

function run_test {
    echo "[RELEASE] Running tests ..."
    ./test.sh
    echo "[RELEASE] Tests completed"
}

function run_package {
    echo "[RELEASE] Packaging ..."
    ./package.sh
    echo "[RELEASE] Packaging completed"
}

function run_publish {
    echo "[RELEASE] Publishing package ..."
    ./publish.sh
    echo "[RELEASE] Package publish completed"
}

echo "[RELEASE] Releasing ..."

run_build

run_test

run_package

run_publish

echo "[RELEASE] Release completed"
