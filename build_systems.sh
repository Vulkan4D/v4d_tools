#!/bin/sh
cd `dirname $0`
cd ..

MODE="$1"
find src/v4d/systems/ -name 'build.sh' -exec sh '{}' $MODE \;
