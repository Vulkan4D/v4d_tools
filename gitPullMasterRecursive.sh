#!/bin/bash
cd `dirname $0`/../

git checkout master
git pull origin master
git submodule update --remote --recursive --init
git submodule foreach --recursive git checkout master
git submodule foreach --recursive git pull origin master

git status

