#!/bin/bash

function find_current_version() {
    CURRENT_VERSION=$(cat metadata.json \
        | grep version \
        | head -1 \
        | awk -F: '{ print $2 }' \
        | xargs \
        | sed 's/[",]//g')

    if [ $? -ne 0 ]; then
        echo "[ERROR] Failed to get current version"
        exit 1
    fi

    echo "Found current version: ${CURRENT_VERSION}"
}

function calculate_release_version() {
    IFS='.'
    read -a tokens <<< "$CURRENT_VERSION"
    major="${tokens[0]}"
    minor="${tokens[1]}"
    remaining="${tokens[2]}"
    patch=$(echo $remaining | awk -F'[^0-9]+' '{ print $1 }')

    if [ "$RELEASE_SCALE" = "major" ]; then
        major=$((major+1))
        minor=0
        patch=0
    elif [ "$RELEASE_SCALE" = "minor" ]; then
        minor=$((minor+1))
        patch=0
    elif [ "$RELEASE_SCALE" = "patch" ]; then
        patch=$((patch+1))
    else
        patch=$((patch+1))
    fi
    RELEASE_VERSION="${major}.${minor}.${patch}"

    echo "Calculated release version: ${RELEASE_VERSION}"
}

function update_to_release_version() {
    sed -i -e "s/${CURRENT_VERSION}/${RELEASE_VERSION}/g" metadata.json

    if [ $? -ne 0 ]; then
        echo "[ERROR] Failed to update to release version"
        exit 1
    fi

    echo "Updated to release version: ${RELEASE_VERSION}"
}

function commit_and_push_release_version() {
    git add .
    git diff-index --quiet HEAD || git commit -m "Release ${RELEASE_VERSION}"
    git push origin HEAD

    echo "Committed and pushed changes for the release version: ${RELEASE_VERSION}"
}

function export_release_version() {
    if [[ ! -z "${GITHUB_ENV}" ]]; then
        echo "RELEASE_VERSION=$RELEASE_VERSION" >> $GITHUB_ENV

        echo "Exported release version: ${RELEASE_VERSION}"
    fi
}

find_current_version
calculate_release_version
update_to_release_version
commit_and_push_release_version
export_release_version
