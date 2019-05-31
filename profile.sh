#!/bin/sh
cd `dirname $0`/../build/release
rm callgrind.out.*
valgrind --tool="callgrind" ./release/demo.linux
kcachegrind callgrind.out.*
rm callgrind.out.*
