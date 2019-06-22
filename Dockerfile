#
# mkvtoolnix Dockerfile
#
# https://github.com/jlesage/docker-mkvtoolnix
#

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.9-v3.5.2

# Define software versions.
ARG MKVTOOLNIX_VERSION=35.0.0
ARG MEDIAINFO_VERSION=19.04

# Define software download URLs.
ARG MKVTOOLNIX_URL=https://mkvtoolnix.download/sources/mkvtoolnix-${MKVTOOLNIX_VERSION}.tar.xz
ARG MEDIAINFO_URL=https://github.com/MediaArea/MediaInfo/archive/v${MEDIAINFO_VERSION}.tar.gz

# Define working directory.
WORKDIR /tmp

# Install dependencies.
RUN add-pkg \
        boost-system \
        boost-regex \
        boost-filesystem \
        libmagic \
        libmatroska \
        libebml \
        flac \
        qt5-qtmultimedia \
        mesa-dri-swrast \
        # For MediaInfo
        libmediainfo \
        qt5-qtsvg \
        && \
    add-pkg cmark-dev --repository http://dl-cdn.alpinelinux.org/alpine/edge/community

# Install MKVToolNix.
RUN \
    # Install packages needed by the build.
    add-pkg --virtual build-dependencies \
        curl \
        patch \
        imagemagick \
        build-base \
        ruby-rake \
        ruby-json \
        qt5-qtbase-dev \
        qt5-qtmultimedia-dev \
        boost-dev \
        file-dev \
        zlib-dev \
        libmatroska-dev \
        flac-dev \
        libogg-dev \
        libvorbis-dev \
        docbook-xsl \
        gettext-dev \
        && \

    # Download the MKVToolNix package.
    echo "Downloading MKVToolNix package..." && \
    curl -# -L ${MKVTOOLNIX_URL} | tar xJ && \

    # Remove embedded profile from PNGs to avoid the "known incorrect sRGB
    # profile" warning.
    find mkvtoolnix-${MKVTOOLNIX_VERSION} -name "*.png" -exec convert -strip {} {} \; && \

    # Compile MKVToolNix.
    cd mkvtoolnix-${MKVTOOLNIX_VERSION} && \
    curl -# -L https://raw.githubusercontent.com/jlesage/docker-mkvtoolnix/master/disable-high-dpi-scaling-override.patch | patch -p1 && \
    env LIBINTL_LIBS=-lintl ./configure \
        --prefix=/usr \
        --mandir=/tmp/mkvtoolnix-man \
        --disable-update-check \
        && \
    rake -j8 && \
    rake install && \
    strip /usr/bin/mkv* && \
    cd .. && \

    # Cleanup.
    del-pkg build-dependencies && \
    rm -rf /tmp/* /tmp/.[!.]*

# Compile and install MediaInfo.
RUN \
    # Install packages needed by the build.
    add-pkg --virtual build-dependencies \
        build-base \
        curl \
        qt5-qtbase-dev \
        libmediainfo-dev \
        && \
    # Download sources.
    echo "Downloading MediaInfo package..." && \
    mkdir mediainfo && \
    curl -# -L ${MEDIAINFO_URL} | tar xz --strip 1 -C mediainfo && \
    # Compile.
    cd mediainfo/Project/QMake/GUI && \
    /usr/lib/qt5/bin/qmake && \
    make -j$(nproc) install && \
    cd ../../../../ && \
    # Install
    strip -v /usr/bin/mediainfo-gui && \
    cd ../ && \
    # Cleanup.
    del-pkg build-dependencies && \
    rm -rf /tmp/* /tmp/.[!.]*

# Adjust the openbox config.
RUN \
    # Maximize only the main/initial window.
    sed-patch 's/<application type="normal">/<application type="normal" name="mkvtoolnix-gui">/' \
        /etc/xdg/openbox/rc.xml && \
    # Make sure the main window is always in the background.
    sed-patch '/<application type="normal" name="mkvtoolnix-gui">/a \    <layer>below</layer>' \
        /etc/xdg/openbox/rc.xml

# Misc adjustments.
RUN  \
    # Clear stuff from /etc/fstab to avoid showing irrelevant devices.
    echo > /etc/fstab

# Generate and install favicons.
RUN \
    APP_ICON_URL=https://github.com/jlesage/docker-templates/raw/master/jlesage/images/mkvtoolnix-icon.png && \
    install_app_icon.sh "$APP_ICON_URL"

# Add files.
COPY rootfs/ /

# Set environment variables.
ENV APP_NAME="MKVToolNix"

# Define mountable directories.
VOLUME ["/config"]
VOLUME ["/storage"]

# Metadata.
LABEL \
      org.label-schema.name="mkvtoolnix" \
      org.label-schema.description="Docker container for MKVToolNix" \
      org.label-schema.version="unknown" \
      org.label-schema.vcs-url="https://github.com/jlesage/docker-mkvtoolnix" \
      org.label-schema.schema-version="1.0"
