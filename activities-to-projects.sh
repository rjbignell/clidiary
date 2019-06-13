#!/bin/bash
#

cat activities.csv | awk -F, '{ print $1 "," $2 }' | sort | uniq >projects.csv
