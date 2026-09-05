#!/usr/bin/env bash

ASTERISK_PACKAGES=(
    # Basic tools
    curl
    wget
    git
    tar
    gzip
    bzip2
    patch
    make
    gcc
    gcc-c++
    autoconf
    automake
    bison
    flex
    pkgconfig
    diffutils
    which
    findutils

    # Asterisk core
    ncurses-devel
    openssl-devel
    libxml2-devel
    sqlite-devel
    libuuid-devel
    jansson-devel
    libedit-devel

    # Python
    python3
    python3-devel

    # SELinux
    policycoreutils
    policycoreutils-python-utils
    checkpolicy
    policycoreutils-devel
)
