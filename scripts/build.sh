#!/bin/bash
REPO_DIR="$WORKSPACE/$REPO"

set -e

cp -r $REPO_DIR ${BUILDDIR}/${REPO}
