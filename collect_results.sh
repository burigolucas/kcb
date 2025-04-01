#!/bin/bash

_=${RSYNC_OPTIONS:="-a --no-o --no-g --no-perms"}

SRC_DIR=$1
DEST_DIR=$2

cd $DEST_DIR

while ((1))
do
  echo "Syncing results with options ${RSYNC_OPTIONS} from $SRC_DIR to $DEST_DIR...";
  rsync ${RSYNC_OPTIONS} $SRC_DIR $DEST_DIR

  echo '<h1>Keycloak Performance Tests</h1>' > index.html.tmp; \
  DATETIME=$(date); \
  echo "<h2>Last updated on: $DATETIME</h2>" >> index.html.tmp; \
  find . \
    -mindepth 2 \
    -name "index.html" \
    -exec printf "<hr><a href = \"%s\">###%s###</a>\n</hr>" {} {} \; \
    >> index.html.tmp; \
  sed -i 's@###\./@@g' index.html.tmp; \
  sed -i 's@/index\.html###@@g' index.html.tmp; \
  mv index.html.tmp index.html; \
  sleep 10; \
done &
