#!/bin/bash

set -e

if [ -z "${INSTALL_DIR}" ]; then
    if [ "$UID" -eq 0 ]; then
        INSTALL_DIR="/usr/bin"
    else
        INSTALL_DIR="$HOME/.local/bin"
    fi
    echo "INSTALL_DIR not set. Defaulting to ${INSTALL_DIR}"
fi

LIB_DIR="`dirname ${INSTALL_DIR}`/lib/youtube-music-updater"
echo $LIB_DIR

mkdir -p ${LIB_DIR}
mkdir -p ${INSTALL_DIR}

install -m 311 json.lua ${LIB_DIR}
install -m 755 youtube-music-updater.lua ${LIB_DIR}
ln -s ${LIB_DIR}/youtube-music-updater.lua ${INSTALL_DIR}/youtube-music-updater

echo "Installed youtube-music-updater."
echo "Ensure ${INSTALL_DIR} is in your PATH"
