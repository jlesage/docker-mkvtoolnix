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

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

function log {
    echo ">>> $*"
}

MKVTOOLNIX_URL="$1"

if [ -z "$MKVTOOLNIX_URL" ]; then
    log "ERROR: MKVToolNix URL missing."
    exit 1
fi

#
# Install required packages.
#
apk --no-cache add \
    curl \
    patch \
    imagemagick \
    py3-pip \
    clang \
    binutils \
    ruby-rake \
    pkgconf \
    qtchooser \
    qt6-qtbase-dev \

xx-apk --no-cache --no-scripts add \
    musl-dev \
    gcc \
    g++ \
    boost-dev \
    gmp-dev \
    flac-dev \
    libogg-dev \
    libvorbis-dev \
    libdvdread-dev \
    zlib-dev \
    qt6-qtbase-dev \
    qt6-qtmultimedia-dev \
    qt6-qtsvg-dev \

xx-apk --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community add \
    cmark-dev \

#
# Download sources.
#

log "Downloading MKVToolNix package..."
mkdir /tmp/mkvtoolnix
curl -# -L -f ${MKVTOOLNIX_URL} | tar xJ --strip 1 -C /tmp/mkvtoolnix

#
# Compile MKVToolNix
#

log "Patching MKVToolNix..."
patch -p1 -d /tmp/mkvtoolnix < "$SCRIPT_DIR"/locale-fix.patch

log "Configuring MKVToolNix..."
(
    cd /tmp/mkvtoolnix && \
    env LIBINTL_LIBS=-lintl ./configure \
        --build=$(TARGETPLATFORM= xx-clang --print-target-triple) \
        --host=$(xx-clang --print-target-triple) \
        --prefix=/usr \
        --disable-update-check \
        --with-boost-libdir=$(xx-info sysroot)/usr/lib \
)

log "Compiling MKVToolNix..."
rake -f /tmp/mkvtoolnix/Rakefile -j$(nproc)

log "Installing MKVToolNix..."
DESTDIR=/tmp/mkvtoolnix-install rake -f /tmp/mkvtoolnix/Rakefile install

# Remove embedded profile from PNGs to avoid the "known incorrect sRGB
# profile" warning.
find /tmp/mkvtoolnix-install -name "*.png" -exec echo "Removing embedded profiles from {}..." ';' -exec mogrify {} ';'
