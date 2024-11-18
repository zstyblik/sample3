#!/usr/bin/env bash
set -e
set -u

cd "$(dirname "${0}")/../app"

python3 -m pytest --junitxml=pytest-result.xml -v .
