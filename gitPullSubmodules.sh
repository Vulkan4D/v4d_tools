#!/bin/bash
cd `dirname $0`/../

# Specific branch for openssl
git submodule update --init src/openssl
git submodule set-branch --branch OpenSSL_1_1_0-stable src/openssl

# Pull All submodules
git submodule update --remote --recursive --init
git submodule foreach --recursive git submodule update

git status
