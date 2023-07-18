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

function package_backend {
    echo "[PACKAGE] Packaging backend app ..."
    sleep 3
    echo "[PACKAGE] Backend app packaging completed"
}

function package_frontend {
    echo "[PACKAGE] Packaging frontend app ..."
    sleep 2
    echo "[PACKAGE] Frontend app packaging completed"
}

function package_mobile {
    echo "[PACKAGE] Packaging mobile app ..."
    sleep 1
    echo "[PACKAGE] Mobile app packaging completed"
}

package_backend

package_frontend

package_mobile
