#
# mkvtoolnix Dockerfile
#
# https://github.com/jlesage/docker-mkvtoolnix
#

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.6-v3.3.4

# Define software versions.
ARG MKVTOOLNIX_VERSION=22.0.0

# Define software download URLs.
ARG MKVTOOLNIX_URL=https://mkvtoolnix.download/sources/mkvtoolnix-${MKVTOOLNIX_VERSION}.tar.xz

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
        && \
    add-pkg cmark --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing

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

    # Fix translation.
    sed-patch 's/# if defined(SYS_APPLE)/# if 1/' mkvtoolnix-${MKVTOOLNIX_VERSION}/src/common/translation.cpp && \

    # Compile MKVToolNix.
    cd mkvtoolnix-${MKVTOOLNIX_VERSION} && \
    env LIBINTL_LIBS=-lintl ./configure \
        --prefix=/usr \
        --disable-update-check \
        --with-docbook-xsl-root=/usr/share/xml/docbook/xsl-stylesheets-1.79.1 && \
    rake install && \
    strip /usr/bin/mkv* && \
    cd .. && \

    # Cleanup.
    del-pkg build-dependencies && \
    rm -rf /tmp/*

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
