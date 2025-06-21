# Docker container for MKVToolNix
[![Release](https://img.shields.io/github/release/jlesage/docker-mkvtoolnix.svg?logo=github&style=for-the-badge)](https://github.com/jlesage/docker-mkvtoolnix/releases/latest)
[![Docker Image Size](https://img.shields.io/docker/image-size/jlesage/mkvtoolnix/latest?logo=docker&style=for-the-badge)](https://hub.docker.com/r/jlesage/mkvtoolnix/tags)
[![Docker Pulls](https://img.shields.io/docker/pulls/jlesage/mkvtoolnix?label=Pulls&logo=docker&style=for-the-badge)](https://hub.docker.com/r/jlesage/mkvtoolnix)
[![Docker Stars](https://img.shields.io/docker/stars/jlesage/mkvtoolnix?label=Stars&logo=docker&style=for-the-badge)](https://hub.docker.com/r/jlesage/mkvtoolnix)
[![Build Status](https://img.shields.io/github/actions/workflow/status/jlesage/docker-mkvtoolnix/build-image.yml?logo=github&branch=master&style=for-the-badge)](https://github.com/jlesage/docker-mkvtoolnix/actions/workflows/build-image.yml)
[![Source](https://img.shields.io/badge/Source-GitHub-blue?logo=github&style=for-the-badge)](https://github.com/jlesage/docker-mkvtoolnix)
[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg?style=for-the-badge)](https://paypal.me/JocelynLeSage)

This is a Docker container for [MKVToolNix](https://mkvtoolnix.download).

The graphical user interface (GUI) of the application can be accessed through a
modern web browser, requiring no installation or configuration on the client

---

[![MKVToolNix logo](https://images.weserv.nl/?url=raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/mkvtoolnix-icon.png&w=110)](https://mkvtoolnix.download)[![MKVToolNix](https://images.placeholders.dev/?width=320&height=110&fontFamily=monospace&fontWeight=400&fontSize=52&text=MKVToolNix&bgColor=rgba(0,0,0,0.0)&textColor=rgba(121,121,121,1))](https://mkvtoolnix.download)

MKVToolNix is a set of tools to create, alter and inspect Matroska files.

---

## Quick Start

**NOTE**:
    The Docker command provided in this quick start is an example, and parameters
    should be adjusted to suit your needs.

Launch the MKVToolNix docker container with the following command:
```shell
docker run -d \
    --name=mkvtoolnix \
    -p 5800:5800 \
    -v /docker/appdata/mkvtoolnix:/config:rw \
    -v /home/user:/storage:rw \
    jlesage/mkvtoolnix
```

Where:

  - `/docker/appdata/mkvtoolnix`: Stores the application's configuration, state, logs, and any files requiring persistency.
  - `/home/user`: Contains files from the host that need to be accessible to the application.

Access the MKVToolNix GUI by browsing to `http://your-host-ip:5800`.
Files from the host appear under the `/storage` folder in the container.

## Documentation

Full documentation is available at https://github.com/jlesage/docker-mkvtoolnix.

## Support or Contact

Having troubles with the container or have questions? Please
[create a new issue](https://github.com/jlesage/docker-mkvtoolnix/issues).

For other Dockerized applications, visit https://jlesage.github.io/docker-apps.
