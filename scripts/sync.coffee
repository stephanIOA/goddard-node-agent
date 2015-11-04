#!/bin/bash

# echo now
echo "Starting to pull down new media"

# execute script to pull down new media using Rsync
rsync -aPzri --delete --progress node@hub.goddard.unicore.io:/var/goddard/media/ /var/goddard/media

# debug
echo "Done pulling media with script"