#!/bin/sh

# Needed to avoid the following error:
#   terminate called after throwing an instance of 'std::runtime_error'
#     what():  locale::facet::_S_create_c_locale name not valid
export LC_ALL=C

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
