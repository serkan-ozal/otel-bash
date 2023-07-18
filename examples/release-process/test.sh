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

function run_unit_tests {
    echo "[TEST] Running unit tests ..."
    sleep 1
    echo "[TEST] Unit tests completed"
}

function run_integration_tests {
    echo "[TEST] Running integration tests ..."
    sleep 2
    echo "[TEST] Integration tests completed"
}

function run_acceptance_tests {
    echo "[TEST] Running acceptance tests ..."
    sleep 3
    echo "[TEST] Acceptance tests completed"
}

run_unit_tests

run_integration_tests

run_acceptance_tests
