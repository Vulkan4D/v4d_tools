#!/bin/sh
find `dirname $0`/.. type f -name "*.gch" -exec rm '{}' \; 

