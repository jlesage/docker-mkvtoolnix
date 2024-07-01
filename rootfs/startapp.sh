#!/bin/sh

if [ -f /config/xdg/config/bunkus.org/mkvtoolnix-gui/mkvtoolnix-gui.ini ]
then
    UI_LOCAL=$(cat /config/xdg/config/bunkus.org/mkvtoolnix-gui/mkvtoolnix-gui.ini | grep "^uiLocal" | cut -d'=' -f2)
    if [ -n "$UI_LOCAL" ]; then
        export LANG="$UI_LOCAL"
    fi
fi

cd /storage
/usr/bin/mkvtoolnix-gui --version
exec /usr/bin/mkvtoolnix-gui

# vim:ft=sh:ts=4:sw=4:et:sts=4
