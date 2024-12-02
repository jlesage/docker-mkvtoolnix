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

# Set to `1` to enable verbose build.
VERBOSE_BUILD=0

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
    qt6-qtmultimedia-dev \
    qt6-qtsvg-dev \

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

# NOTE: During the configure phase, Qt6 related checks (`ac/qt6.m4`) are done
#       with qmake6, which doesn't work for cross-compilation.  Thus, the checks
#       are done against the builder host's Qt6 installation (not against the
#       target one).
log "Configuring MKVToolNix..."
sed -i 's/$${CROSS_COMPILE}clang/xx-clang/g' /usr/lib/qt6/mkspecs/common/clang.conf
(
    cd /tmp/mkvtoolnix && \
    env LIBINTL_LIBS=-lintl ./configure \
        am_cv_qt6_compilation=1 \
        --build=$(TARGETPLATFORM= xx-clang --print-target-triple) \
        --host=$(xx-clang --print-target-triple) \
        --prefix=/usr \
        --disable-update-check \
        --with-boost-libdir=$(xx-info sysroot)/usr/lib \
        --with-qmake6=/usr/bin/qmake6 \
)

# Paths used in QT_FLAGS, QT_LIBS and QT_LIBS_NON_GUI variables (defined in
# build-config) need to be adjusted to use the ones of the build target.
sed -i "s|-I/usr/|-I$(xx-info sysroot)usr/|g" /tmp/mkvtoolnix/build-config
sed -i "s| /usr/lib/| $(xx-info sysroot)usr/lib/|g" /tmp/mkvtoolnix/build-config
sed -i "s| -Wl,-rpath,/usr/lib | -Wl,-rpath-link,$(xx-info sysroot)usr/lib:$(xx-info sysroot)usr/lib/pulseaudio:$(xx-info sysroot)/usr/lib/libproxy |g" /tmp/mkvtoolnix/build-config

# Make sure to use tools from the builder host.
sed -i "s|MOC = .*|MOC = /usr/lib/qt6/libexec/moc|" /tmp/mkvtoolnix/build-config
sed -i "s|RCC = .*|RCC = /usr/lib/qt6/libexec/rcc|" /tmp/mkvtoolnix/build-config
sed -i "s|UIC = .*|UIC = /usr/lib/qt6/libexec/uic|" /tmp/mkvtoolnix/build-config

log "Compiling MKVToolNix..."
rake V=${VERBOSE_BUILD:-0} -f /tmp/mkvtoolnix/Rakefile -j$(nproc)

log "Installing MKVToolNix..."
DESTDIR=/tmp/mkvtoolnix-install rake -f /tmp/mkvtoolnix/Rakefile install

# Remove embedded profile from PNGs to avoid the "known incorrect sRGB
# profile" warning.
find /tmp/mkvtoolnix-install -name "*.png" -exec echo "Removing embedded profiles from {}..." ';' -exec mogrify {} ';'
