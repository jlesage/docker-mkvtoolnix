#
# mkvtoolnix Dockerfile
#
# https://github.com/jlesage/docker-mkvtoolnix
#

# Docker image version is provided via build arg.
ARG DOCKER_IMAGE_VERSION=

# Define software versions.
ARG MKVTOOLNIX_VERSION=88.0
ARG MEDIAINFO_VERSION=24.11
ARG MEDIAINFOLIB_VERSION=24.11
ARG ZENLIB_VERSION=0.4.41

# Define software download URLs.
ARG MKVTOOLNIX_URL=https://mkvtoolnix.download/sources/mkvtoolnix-${MKVTOOLNIX_VERSION}.tar.xz
ARG MEDIAINFO_URL=https://mediaarea.net/download/source/mediainfo/${MEDIAINFO_VERSION}/mediainfo_${MEDIAINFO_VERSION}.tar.gz
ARG MEDIAINFOLIB_URL=https://mediaarea.net/download/source/libmediainfo/${MEDIAINFO_VERSION}/libmediainfo_${MEDIAINFOLIB_VERSION}.tar.xz
ARG ZENLIB_URL=https://mediaarea.net/download/source/libzen/${ZENLIB_VERSION}/libzen_${ZENLIB_VERSION}.tar.gz

# Get Dockerfile cross-compilation helpers.
FROM --platform=$BUILDPLATFORM tonistiigi/xx AS xx

# Build MKVToolNix.
FROM --platform=$BUILDPLATFORM alpine:3.20 AS mkvtoolnix
ARG TARGETPLATFORM
ARG MKVTOOLNIX_URL
COPY --from=xx / /
COPY src/mkvtoolnix /build
RUN /build/build.sh "$MKVTOOLNIX_URL"
RUN xx-verify \
    /tmp/mkvtoolnix-install/usr/bin/mkvmerge \
    /tmp/mkvtoolnix-install/usr/bin/mkvinfo \
    /tmp/mkvtoolnix-install/usr/bin/mkvextract \
    /tmp/mkvtoolnix-install/usr/bin/mkvpropedit \
    /tmp/mkvtoolnix-install/usr/bin/mkvtoolnix-gui

# Build MediaInfo.
FROM --platform=$BUILDPLATFORM alpine:3.20 AS mediainfo
ARG TARGETPLATFORM
ARG MEDIAINFO_URL
ARG MEDIAINFOLIB_URL
ARG ZENLIB_URL
COPY --from=xx / /
COPY src/mediainfo /build
RUN /build/build.sh "$MEDIAINFO_URL" "$MEDIAINFOLIB_URL" "$ZENLIB_URL"
RUN xx-verify \
    /tmp/mediainfo-install/usr/bin/mediainfo-gui \
    /tmp/mediainfo-install/usr/lib/libmediainfo.so \
    /tmp/mediainfo-install/usr/lib/libzen.so

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.20-v4.6.7

ARG MKVTOOLNIX_VERSION
ARG DOCKER_IMAGE_VERSION

# Define working directory.
WORKDIR /tmp

# Install dependencies.
RUN add-pkg \
        boost1.84-filesystem \
        font-croscore \
        flac \
        libdvdread \
        tinyxml2 \
        qt6-qtbase-x11 \
        qt6-qtmultimedia \
        libcmark \
        fmt \
        # Needed for icons.
        qt6-qtsvg \
        # Needed for dark mode.
        adwaita-qt6 \
        # mesa-gl dependency is not automatically pulled with some architectures
        # (e.g. arm64).
        mesa-gl \
        && \
    # Remove unused plugins that cause the following log message:
    #   Plugin uses incompatible Qt library (6.6.0) [release]
    rm -v /usr/lib/qt6/plugins/platforms/libqwayland-*

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
COPY --from=mkvtoolnix /tmp/mkvtoolnix-install/usr/bin /usr/bin
COPY --from=mkvtoolnix /tmp/mkvtoolnix-install/usr/share/icons /usr/share/icons
COPY --from=mkvtoolnix /tmp/mkvtoolnix-install/usr/share/locale /usr/share/locale
COPY --from=mkvtoolnix /tmp/mkvtoolnix-install/usr/share/mkvtoolnix/qt_resources.rcc /usr/share/mkvtoolnix/qt_resources.rcc
COPY --from=mediainfo /tmp/mediainfo-install/usr/bin /usr/bin
COPY --from=mediainfo /tmp/mediainfo-install/usr/lib /usr/lib/

# Set internal environment variables.
RUN \
    set-cont-env APP_NAME "MKVToolNix" && \
    set-cont-env APP_VERSION "$MKVTOOLNIX_VERSION" && \
    set-cont-env DOCKER_IMAGE_VERSION "$DOCKER_IMAGE_VERSION" && \
    true

# Define mountable directories.
VOLUME ["/storage"]

# Metadata.
LABEL \
      org.label-schema.name="mkvtoolnix" \
      org.label-schema.description="Docker container for MKVToolNix" \
      org.label-schema.version="${DOCKER_IMAGE_VERSION:-unknown}" \
      org.label-schema.vcs-url="https://github.com/jlesage/docker-mkvtoolnix" \
      org.label-schema.schema-version="1.0"
