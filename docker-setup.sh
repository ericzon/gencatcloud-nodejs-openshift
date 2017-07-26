#!/bin/bash

# setup directory for data
mkdir -p /data
chown -R node:0 /data
restorecon -R /data
chmod g+w -R /data
