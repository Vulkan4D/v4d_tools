#!/bin/sh
PROJECT_DIR="`dirname $0`/.."
cd $PROJECT_DIR

rm -rf src/v4d/core/common.hh.gch
rm -rf build/release/*
rm -rf build/debug/*
