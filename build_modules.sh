#!/bin/sh
cd `dirname $0`
cd ..

MODE="$1"
find src/v4d/modules/ -name 'build.sh' -exec sh '{}' $MODE \;
