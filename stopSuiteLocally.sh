#!/usr/bin/env bash

source ./functions.sh

ORG_DIR=`pwd`
TEMP_DIR=`mktemp -d` && cd $TEMP_DIR

echo "Stop the suite..."
cleanup

### Cleanup
cd $ORG_DIR
rm -rf $TEMP_DIR

