#!/bin/sh -e

mkdir -p dist

zip -r dist/key-jump-${npm_package_version}.zip src
