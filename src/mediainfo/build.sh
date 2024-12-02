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

export PKG_CONFIG_PATH=/$(xx-info)/usr/lib/pkgconfig

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

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
    cmake \
    ninja \
    patch \
    autoconf \
    automake \
    libtool \
    pkgconf \
    qt6-qtbase-dev \

xx-apk --no-cache --no-scripts add \
    musl-dev \
    gcc \
    g++ \
    tinyxml2-dev \
    zlib-dev \
    qt6-qtbase-dev \

#
# Download sources.
#

log "Downloading MediaInfo package..."
mkdir /tmp/MediaInfo
curl -# -L -f ${MEDIAINFO_URL} | tar xz --strip 1 -C /tmp/MediaInfo

log "Downloading MediaInfoLib package..."
mkdir /tmp/MediaInfoLib
curl -# -L -f ${MEDIAINFOLIB_URL} | tar xJ --strip 1 -C /tmp/MediaInfoLib
rm -r \
    /tmp/MediaInfoLib/Project/MS* \
    /tmp/MediaInfoLib/Project/zlib \
    /tmp/MediaInfoLib/Source/ThirdParty/tinyxml2 \

log "Downloading ZenLib package..."
mkdir /tmp/ZenLib
curl -# -L -f ${ZENLIB_URL} | tar xz --strip 1 -C /tmp/ZenLib

#
# Compile MediaInfoLib
#

log "Configuring MediaInfoLib..."
(
    cd /tmp/MediaInfoLib && \
    cmake -G Ninja -S Project/CMake -B build \
        $(xx-clang --print-cmake-defines) \
        -DCMAKE_FIND_ROOT_PATH=$(xx-info sysroot) \
        -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
        -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
        -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY \
        -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
        -DCMAKE_BUILD_TYPE=MinSizeRel \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_VERBOSE_MAKEFILE=ON \
        -DBUILD_SHARED_LIBS=ON \
        -DBUILD_ZENLIB=ON \
)

log "Compiling MediaInfoLib..."
cmake --build /tmp/MediaInfoLib/build

log "Installing MediaInfoLib..."
DESTDIR=/tmp/mediainfo-install cmake --install /tmp/MediaInfoLib/build
DESTDIR=$(xx-info sysroot) cmake --install /tmp/MediaInfoLib/build

#
# Compile MediaInfo GUI
# NOTE: The UI under MediaInfo/Project/GNU/GUI is not the correct one!
#

log "Patching MediaInfo GUI..."
patch -p1 -d /tmp/MediaInfo < "$SCRIPT_DIR"/disable-update.patch

log "Configuring MediaInfo GUI..."
sed -i 's/$${CROSS_COMPILE}clang/xx-clang/g' /usr/lib/qt6/mkspecs/common/clang.conf
(
    cd /tmp/MediaInfo/Project/QMake/GUI && \
    /usr/lib/qt6/bin/qmake -spec linux-clang
)
sed -i "s| /usr/lib/libQt6| $(xx-info sysroot)usr/lib/libQt6|g" /tmp/MediaInfo/Project/QMake/GUI/Makefile
sed -i "s| /usr/lib/libGL.so | $(xx-info sysroot)/usr/lib/libGL.so |g" /tmp/MediaInfo/Project/QMake/GUI/Makefile
sed -i "s|LFLAGS        = .*|LFLAGS        = $LDFLAGS|" /tmp/MediaInfo/Project/QMake/GUI/Makefile

log "Compiling MediaInfo GUI..."
make -C /tmp/MediaInfo/Project/QMake/GUI -j$(nproc)

log "Installing MediaInfo GUI..."
make INSTALL_ROOT=/tmp/mediainfo-install -C /tmp/MediaInfo/Project/QMake/GUI install

log "Cleaning installation..."
find /tmp/mediainfo-install/usr/lib -mindepth 1 -not -name "*.so*" -exec echo "Removing {}..." ';' -delete
