#!/usr/bin/env bash

cd "$(dirname "${0}")/.."

./ci/run-flake8.sh
./ci/run-black.sh diff
./ci/run-reorder-python-imports.sh
