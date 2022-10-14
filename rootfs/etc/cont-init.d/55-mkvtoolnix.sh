#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

# Generate machine id.
if [ ! -f /config/machine-id ]; then
    echo "generating machine-id..."
    cat /proc/sys/kernel/random/uuid | tr -d '-' > /config/machine-id
fi

mkdir -p "$XDG_CONFIG_HOME/bunkus.org/mkvtoolnix-gui"

# Upgrade previous installations.
[ ! -f /config/mkvtoolnix-gui.ini ] || mv -v /config/mkvtoolnix-gui.ini "$XDG_CONFIG_HOME/bunkus.org/mkvtoolnix-gui/"
[ ! -d /config/jobQueue ] || mv -v /config/jobQueue "$XDG_CONFIG_HOME/bunkus.org/mkvtoolnix-gui/"
[ ! -f /config/QtProject.conf ] || mv -v /config/QtProject.conf "$XDG_CONFIG_HOME/"
[ ! -f "$XDG_CONFIG_HOME/bunkus.org/mkvtoolnix-gui/mkvtoolnix-gui.ini" ] || sed -i 's/^uiLocale=$/uiLocale=en_US/' "$XDG_CONFIG_HOME/bunkus.org/mkvtoolnix-gui/mkvtoolnix-gui.ini"

# Copy default configuration files if needed.
[ -f "$XDG_CONFIG_HOME/bunkus.org/mkvtoolnix-gui/mkvtoolnix-gui.ini" ] || cp -v /defaults/mkvtoolnix-gui.ini "$XDG_CONFIG_HOME/bunkus.org/mkvtoolnix-gui/"
[ -f "$XDG_CONFIG_HOME/QtProject.conf" ] || cp -v /defaults/QtProject.conf "$XDG_CONFIG_HOME/"

# vim: set ft=sh :
