#!/bin/bash
#cd into the directory that Animus is in, then run this script to launch the visualizer

echo "creating temporary bin"
CWD=$(pwd)
processing-java --sketch=$CWD --output="$CWD/tmp" --force --present

echo "removing temporary bin"
rm -rf tmp

