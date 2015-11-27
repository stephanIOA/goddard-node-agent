#!/usr/bin/env bash

cd /var/goddard/agent
pkill -15 -f sync.sh || true
chmod a+x scripts/sync.sh
./scripts/sync.sh
