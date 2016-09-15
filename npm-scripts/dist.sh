#!/bin/sh -e

./npm-scripts/build.sh

mkdir -p dist

zip -r dist/key-jump-${npm_package_version}.zip build
