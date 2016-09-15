#!/bin/bash -e

./npm-scripts/clean.sh

mkdir -p build

cp \
	src/manifest.json \
	src/icon*.png \
	src/options.html \
	build

# `sed -i ""` must be used instead of `sed -i` or we'll get a "undefined label"
# error on OS X.
sed -i "" "s/{{version}}/${npm_package_version}/" build/manifest.json

if [ "$1" = "watch" ]; then
	webpack --progress --colors --watch
else
	webpack --progress --colors
fi
