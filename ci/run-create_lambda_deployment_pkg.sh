#!/usr/bin/env bash
set -e
set -u
set -x

cd "$(dirname "${0}")/.."
rm -rf ./build ./deployment-package.zip
mkdir build

pip \
    install \
    --target ./build \
    -r ./app/requirements/requirements.txt

cd build
zip -r ../deployment-package.zip .

cd ../app
zip -r ../deployment-package.zip weather.py templates/
