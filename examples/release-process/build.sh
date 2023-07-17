#!/bin/bash

. ../../otel_bash.sh

# or get the latest version of the "otel-bash" from remote
# . /dev/stdin <<< "$(curl -s https://raw.githubusercontent.com/serkan-ozal/otel-bash/master/otel_bash.sh)"

# or get specific version (v<version>) of the "otel-bash" from remote
# for example, "v0.0.1" for the "0.0.1" version of the "otel-bash"
# . /dev/stdin <<< "$(curl -s https://raw.githubusercontent.com/serkan-ozal/otel-bash/v0.0.1/otel_bash.sh)"

function setup_build_env {
    echo "[BUILD] Setting up build environment ..."
    sleep 3
    echo "[BUILD] Build environment setup completed"
}

function install_dependencies {
    echo "[BUILD] Installing dependencies ..."
    sleep 2
    echo "[BUILD] Installed dependencies"
}

function compile_sources {
    echo "[BUILD] Compiling sources ..."
    sleep 1
    echo "[BUILD] Source compilation completed"
}

setup_build_env

install_dependencies

compile_sources
