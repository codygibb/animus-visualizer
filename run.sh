#!/bin/bash
#cd into the directory that Animus is in, then run this script to launch the visualizer

CWD=$(pwd)
processing-java --sketch=$CWD --output="$CWD/tmp" --force --present

# --output creates a folder for all class files, so this deletes it afterwards
rm -rf tmp

