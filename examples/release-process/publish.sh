#!/bin/bash

. ../../otel_bash.sh

# or get the latest version of the "otel-bash" from remote
# . /dev/stdin <<< "$(curl -s https://raw.githubusercontent.com/serkan-ozal/otel-bash/master/otel_bash.sh)"

# or get specific version (v<version>) of the "otel-bash" from remote
# for example, "v0.0.1" for the "0.0.1" version of the "otel-bash"
# . /dev/stdin <<< "$(curl -s https://raw.githubusercontent.com/serkan-ozal/otel-bash/v0.0.1/otel_bash.sh)"

function publish_backend {
    echo "[PUBLISH] Publishing backend app ..."
    sleep 3
    echo "[PUBLISH] Published backend app"
}

function publish_frontend {
    echo "[PUBLISH] Publishing frontend app ..."
    sleep 2
    echo "[PUBLISH] Published frontend app"
}

function publish_mobile {
    echo "[PUBLISH] Publishing mobile app ..."
    sleep 1
    echo "[PUBLISH] Published mobile app"
}

publish_backend

publish_frontend

publish_mobile
