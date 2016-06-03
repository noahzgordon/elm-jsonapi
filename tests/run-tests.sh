#!/bin/sh

cd "$(dirname "$0")"
set -e

elm-package install -y

elm-make --yes --output test.js Test.elm
node test.js
