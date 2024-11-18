#!/usr/bin/env bash
set -u

# get highest tag number
VERSION=$(git describe --abbrev=0 --tags 2>/dev/null)
if [ -z "${VERSION}" ]; then
    VERSION="v0.0.0"
fi

# replace . with space so can split into an array
IFS="." read -r -a VERSION_BITS <<< "${VERSION}"

# get number parts and increase last one by 1
VNUM1=${VERSION_BITS[0]}
VNUM1=${VNUM1:1}
VNUM2=${VERSION_BITS[1]}
VNUM3=${VERSION_BITS[2]}
VNUM3=$((VNUM3+1))

# create new tag
NEW_TAG="v${VNUM1}.${VNUM2}.${VNUM3}"
echo "Updating ${VERSION} to ${NEW_TAG}"

# get current hash and see if it already has a tag
GIT_COMMIT=$(git rev-parse HEAD)
NEEDS_TAG=$(git describe --contains "${GIT_COMMIT}" 2>/dev/null)

# only tag if no tag already
if [ -z "${NEEDS_TAG}" ]; then
    git tag "${NEW_TAG}"
    echo "Tagged with ${NEW_TAG}"
    echo "DO NOT FORGET TO 'git push --tags'"
else
    echo "This commit is already tagged"
fi
