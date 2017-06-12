#!/usr/bin/with-contenv sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

# Generate machine id.
echo "Generating machine-id..."
cat /proc/sys/kernel/random/uuid | tr -d '-' > /etc/machine-id

# Copy default configuration files if needed.
for FILE in mkvtoolnix-gui.ini QtProject.conf
do
  if [ ! -f /config/$FILE ]; then
    cp /defaults/$FILE /config/
  fi
done

# Take ownership of the config directory.
chown -R $USER_ID:$GROUP_ID /config

# vim: set ft=sh :
