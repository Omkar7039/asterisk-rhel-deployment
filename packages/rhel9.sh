#!/usr/bin/env bash

ASTERISK_PACKAGES=(
    # Build tools
    make
    gcc
    gcc-c++
    pkgconfig
    autoconf
    automake
    autoconf-archive
    bison
    flex
    patch
    wget
    curl
    git
    tar
    gzip
    bzip2
    which
    findutils
    diffutils

    # Asterisk core build dependencies
    libedit-devel
    jansson-devel
    libuuid-devel
    sqlite-devel
    libxml2-devel
    openssl-devel
    ncurses-devel

    # Common Asterisk optional/add-on dependencies
    speex-devel
    speexdsp-devel
    libogg-devel
    libvorbis-devel
    portaudio-devel
    libcurl-devel
    xmlstarlet
    postgresql-devel
    unixODBC-devel
    lua-devel
    uriparser-devel
    libxslt-devel
    bluez-libs-devel
    radcli-devel
    freetds-devel
    jack-audio-connection-kit-devel
    bash
    libcap-devel
    net-snmp-devel
    newt-devel
    popt-devel
    libical-devel
    spandsp-devel
    libresample-devel
    binutils-devel
    libsrtp-devel
    gsm-devel
    zlib-devel
    openldap-devel
    codec2-devel
    fftw-devel
    libsndfile-devel
    unbound-devel

    # Python
    python3
    python3-devel

    # SELinux
    policycoreutils
    policycoreutils-python-utils
    checkpolicy
    policycoreutils-devel
)
