#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

# Set same default compilation flags as abuild.
export CFLAGS="-Os -fomit-frame-pointer"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="$CFLAGS"
export LDFLAGS="-Wl,--strip-all -Wl,--as-needed"

export CC=xx-clang
export CXX=xx-clang++

function log {
    echo ">>> $*"
}

MEDIAINFO_URL="$1"
MEDIAINFOLIB_URL="$2"
ZENLIB_URL="$3"

if [ -z "$MEDIAINFO_URL" ]; then
    log "ERROR: MediaInfo URL missing."
    exit 1
fi

if [ -z "$MEDIAINFOLIB_URL" ]; then
    log "ERROR: MediaInfoLib URL missing."
    exit 1
fi

if [ -z "$ZENLIB_URL" ]; then
    log "ERROR: ZenLib URL missing."
    exit 1
fi

#
# Install required packages.
#
apk --no-cache add \
    curl \
    clang \
    make \
    autoconf \
    automake \
    libtool \
    pkgconf \
    qtchooser \
    qt5-qtbase-dev \

xx-apk --no-cache --no-scripts add \
    musl-dev \
    gcc \
    g++ \
    tinyxml2-dev \
    zlib-dev \
    qt5-qtbase-dev \

#
# Download sources.
#

log "Downloading MediaInfo package..."
mkdir /tmp/MediaInfo
curl -# -L ${MEDIAINFO_URL} | tar xz --strip 1 -C /tmp/MediaInfo

log "Downloading MediaInfoLib package..."
mkdir /tmp/MediaInfoLib
curl -# -L ${MEDIAINFOLIB_URL} | tar xJ --strip 1 -C /tmp/MediaInfoLib
rm -r \
    /tmp/MediaInfoLib/Project/MS* \
    /tmp/MediaInfoLib/Project/zlib \
    /tmp/MediaInfoLib/Source/ThirdParty/tinyxml2 \

log "Downloading ZenLib package..."
mkdir /tmp/ZenLib
curl -# -L ${ZENLIB_URL} | tar xz --strip 1 -C /tmp/ZenLib

#
# Compile ZenLib
#

log "Configuring ZenLib..."
(
    cd /tmp/ZenLib/Project/GNU/Library && \
    ./autogen.sh && \
    ./configure \
        --build=$(TARGETPLATFORM= xx-clang --print-target-triple) \
        --host=$(xx-clang --print-target-triple) \
        --prefix=/usr \
        --disable-static \
        --enable-shared \
)

log "Compiling ZenLib..."
make -C /tmp/ZenLib/Project/GNU/Library -j$(nproc)

log "Installing ZenLib..."
make DESTDIR=/tmp/mediainfo-install -C /tmp/ZenLib/Project/GNU/Library install

#
# Compile MediaInfoLib
#

log "Configuring MediaInfoLib..."
(
    cd /tmp/MediaInfoLib/Project/GNU/Library && \
    ./autogen.sh && \
    ./configure \
        --build=$(TARGETPLATFORM= xx-clang --print-target-triple) \
        --host=$(xx-clang --print-target-triple) \
        --prefix=/usr \
        --disable-static \
        --enable-shared \
        --with-libtinyxml2 \
)

log "Compiling MediaInfoLib..."
make -C /tmp/MediaInfoLib/Project/GNU/Library -j$(nproc)

log "Installing MediaInfoLib..."
make DESTDIR=/tmp/mediainfo-install -C /tmp/MediaInfoLib/Project/GNU/Library install

#
# Compile MediaInfo GUI
# NOTE: The UI under MediaInfo/Project/GNU/GUI is not the correct one!
#

log "Configuring MediaInfo GUI..."
sed -i 's/$${CROSS_COMPILE}clang/xx-clang/g' /usr/lib/qt5/mkspecs/common/clang.conf
(
    cd /tmp/MediaInfo/Project/QMake/GUI && \
    qmake -spec linux-clang
)
sed -i "s| /usr/lib/libQt5| $(xx-info sysroot)usr/lib/libQt5|g" /tmp/MediaInfo/Project/QMake/GUI/Makefile
sed -i "s|LFLAGS        = .*|LFLAGS        = $LDFLAGS|" /tmp/MediaInfo/Project/QMake/GUI/Makefile

log "Compiling MediaInfo GUI..."
make V=1 -C /tmp/MediaInfo/Project/QMake/GUI -j$(nproc)

log "Installing MediaInfo GUI..."
make INSTALL_ROOT=/tmp/mediainfo-install -C /tmp/MediaInfo/Project/QMake/GUI install

log "Cleaning installation..."
find /tmp/mediainfo-install/usr/lib -mindepth 1 -not -name "*.so*" -exec echo "Removing {}..." ';' -delete
