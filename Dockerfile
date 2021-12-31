#
# mkvtoolnix Dockerfile
#
# https://github.com/jlesage/docker-mkvtoolnix
#

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.12-v3.5.7

# Docker image version is provided via build arg.
ARG DOCKER_IMAGE_VERSION=unknown

# Define software versions.
ARG MKVTOOLNIX_VERSION=64.0.0
ARG MEDIAINFO_VERSION=21.09

# Define software download URLs.
ARG MKVTOOLNIX_URL=https://mkvtoolnix.download/sources/mkvtoolnix-${MKVTOOLNIX_VERSION}.tar.xz
ARG MEDIAINFO_URL=https://github.com/MediaArea/MediaInfo/archive/v${MEDIAINFO_VERSION}.tar.gz
ARG MEDIAINFOLIB_URL=https://mediaarea.net/download/source/libmediainfo/${MEDIAINFO_VERSION}/libmediainfo_${MEDIAINFO_VERSION}.tar.xz

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
        qt5-qttranslations \
        mesa-dri-swrast \
        pcre2 \
        # For MediaInfo
        qt5-qtsvg \
        libcurl \
        libzen \
        tinyxml2 \
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
        pcre2-dev \
        gmp-dev \
        && \
    # Set same default compilation flags as abuild.
    export CFLAGS="-Os -fomit-frame-pointer" && \
    export CXXFLAGS="$CFLAGS" && \
    export CPPFLAGS="$CFLAGS" && \
    export LDFLAGS="-Wl,--as-needed" && \
    # Download the MKVToolNix package.
    echo "Downloading MKVToolNix package..." && \
    curl -# -L ${MKVTOOLNIX_URL} | tar xJ && \
    # Remove embedded profile from PNGs to avoid the "known incorrect sRGB
    # profile" warning.
    find mkvtoolnix-${MKVTOOLNIX_VERSION} -name "*.png" -exec convert -strip {} {} \; && \
    # Compile MKVToolNix.
    cd mkvtoolnix-${MKVTOOLNIX_VERSION} && \
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
        cmake \
        automake \
        autoconf \
        libtool \
        curl-dev \
        libmms-dev \
        libzen-dev \
        tinyxml2-dev \
        qt5-qtbase-dev \
        && \
    # Set same default compilation flags as abuild.
    export CFLAGS="-Os -fomit-frame-pointer" && \
    export CXXFLAGS="$CFLAGS" && \
    export CPPFLAGS="$CFLAGS" && \
    export LDFLAGS="-Wl,--as-needed" && \
    # Download MediaInfoLib.
    echo "Downloading MediaInfoLib package..." && \
    mkdir MediaInfoLib && \
    curl -# -L ${MEDIAINFOLIB_URL} | tar xJ --strip 1 -C MediaInfoLib && \
    rm -r \
        MediaInfoLib/Project/MS* \
        MediaInfoLib/Project/zlib \
        MediaInfoLib/Source/ThirdParty/tinyxml2 \
        && \
    cd MediaInfoLib && \
    curl -# -L https://github.com/MediaArea/MediaInfoLib/commit/cd6d5cb1cfe03d4fcef8fd38decd04765c19890a.patch | patch -p1 && \
    cd .. && \
    # Compile MediaInfoLib.
    echo "Compiling MediaInfoLib..." && \
    cd MediaInfoLib/Project/CMake && \
    cmake -DCMAKE_BUILD_TYPE=None \
          -DCMAKE_INSTALL_PREFIX=/usr \
          -DCMAKE_VERBOSE_MAKEFILE=OFF \
          -DBUILD_SHARED_LIBS=ON \
          && \
    make -j$(nproc) install && \
    cd ../../../ && \
    # Download MediaInfo.
    echo "Downloading MediaInfo package..." && \
    mkdir MediaInfo && \
    curl -# -L ${MEDIAINFO_URL} | tar xz --strip 1 -C MediaInfo && \
    # Compile the GUI.
    echo "Compiling MediaInfo GUI..." && \
    cd MediaInfo/Project/QMake/GUI && \
    /usr/lib/qt5/bin/qmake && \
    make -j$(nproc) install && \
    cd ../../../../ && \
    # Compile the CLI.
    echo "Compiling MediaInfo CLI..." && \
    cd MediaInfo/Project/GNU/CLI && \
    ./autogen.sh && \
    ./configure \
        --prefix=/usr \
        --enable-static=no \
        && \
    make -j$(nproc) install && \
    # Strip binaries.
    strip -v /usr/bin/mediainfo && \
    strip -v /usr/bin/mediainfo-gui && \
    strip -v /usr/lib/libmediainfo.so && \
    cd ../ && \
    # Cleanup.
    rm -r \
        /usr/include/MediaInfo \
        /usr/include/MediaInfoDLL \
        /usr/lib/cmake/mediainfolib \
        /usr/lib/pkgconfig/libmediainfo.pc \
        && \
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
      org.label-schema.version="$DOCKER_IMAGE_VERSION" \
      org.label-schema.vcs-url="https://github.com/jlesage/docker-mkvtoolnix" \
      org.label-schema.schema-version="1.0"
