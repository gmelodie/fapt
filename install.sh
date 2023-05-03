#!/bin/sh
# script stolen from https://tailscale.com/install.sh
# Copyright (c) Tailscale Inc & AUTHORS
# SPDX-License-Identifier: BSD-3-Clause
#
# This script detects the current operating system, and installs
# Tailscale according to that OS's conventions.

set -eu

# Step 1: detect the current linux distro, version, and packaging system.
#
# We rely on a combination of 'uname' and /etc/os-release to find
# an OS name and version, and from there work out what
# installation method we should be using.
#
# The end result of this step is that the following three
# variables are populated, if detection was successful.
OS=""
VERSION=""
PACKAGETYPE=""
APT_KEY_TYPE="" # Only for apt-based distros
APT_SYSTEMCTL_START=false # Only needs to be true for Kali
TRACK="${TRACK:-stable}"

case "$TRACK" in
    stable|unstable)
        ;;
    *)
        echo "unsupported track $TRACK"
        exit 1
        ;;
esac

if [ -f /etc/os-release ]; then
    # /etc/os-release populates a number of shell variables. We care about the following:
    #  - ID: the short name of the OS (e.g. "debian", "freebsd")
    #  - VERSION_ID: the numeric release version for the OS, if any (e.g. "18.04")
    #  - VERSION_CODENAME: the codename of the OS release, if any (e.g. "buster")
    #  - UBUNTU_CODENAME: if it exists, use instead of VERSION_CODENAME
    . /etc/os-release
    case "$ID" in
        ubuntu|pop|neon|zorin)
            OS="ubuntu"
            if [ "${UBUNTU_CODENAME:-}" != "" ]; then
                VERSION="$UBUNTU_CODENAME"
            else
                VERSION="$VERSION_CODENAME"
            fi
            PACKAGETYPE="apt"
            # Third-party keyrings became the preferred method of
            # installation in Ubuntu 20.04.
            if expr "$VERSION_ID" : "2.*" >/dev/null; then
                APT_KEY_TYPE="keyring"
            else
                APT_KEY_TYPE="legacy"
            fi
            ;;
        debian)
            OS="$ID"
            VERSION="$VERSION_CODENAME"
            PACKAGETYPE="apt"
            # Third-party keyrings became the preferred method of
            # installation in Debian 11 (Bullseye).
            if [ -z "${VERSION_ID:-}" ]; then
                # rolling release. If you haven't kept current, that's on you.
                APT_KEY_TYPE="keyring"
            elif [ "$VERSION_ID" -lt 11 ]; then
                APT_KEY_TYPE="legacy"
            else
                APT_KEY_TYPE="keyring"
            fi
            ;;
        linuxmint)
            if [ "${UBUNTU_CODENAME:-}" != "" ]; then
                OS="ubuntu"
                VERSION="$UBUNTU_CODENAME"
            elif [ "${DEBIAN_CODENAME:-}" != "" ]; then
                OS="debian"
                VERSION="$DEBIAN_CODENAME"
            else
                OS="ubuntu"
                VERSION="$VERSION_CODENAME"
            fi
            PACKAGETYPE="apt"
            if [ "$VERSION_ID" -lt 5 ]; then
                APT_KEY_TYPE="legacy"
            else
                APT_KEY_TYPE="keyring"
            fi
            ;;
        elementary)
            OS="ubuntu"
            VERSION="$UBUNTU_CODENAME"
            PACKAGETYPE="apt"
            if [ "$VERSION_ID" -lt 6 ]; then
                APT_KEY_TYPE="legacy"
            else
                APT_KEY_TYPE="keyring"
            fi
            ;;
        parrot|mendel)
            OS="debian"
            PACKAGETYPE="apt"
            if [ "$VERSION_ID" -lt 5 ]; then
                VERSION="buster"
                APT_KEY_TYPE="legacy"
            else
                VERSION="bullseye"
                APT_KEY_TYPE="keyring"
            fi
            ;;
        galliumos)
            OS="ubuntu"
            PACKAGETYPE="apt"
            VERSION="bionic"
            APT_KEY_TYPE="legacy"
            ;;
        pureos)
            OS="debian"
            PACKAGETYPE="apt"
            VERSION="bullseye"
            APT_KEY_TYPE="keyring"
            ;;
        raspbian)
            OS="$ID"
            VERSION="$VERSION_CODENAME"
            PACKAGETYPE="apt"
            # Third-party keyrings became the preferred method of
            # installation in Raspbian 11 (Bullseye).
            if [ "$VERSION_ID" -lt 11 ]; then
                APT_KEY_TYPE="legacy"
            else
                APT_KEY_TYPE="keyring"
            fi
            ;;
        kali)
            OS="debian"
            PACKAGETYPE="apt"
            YEAR="$(echo "$VERSION_ID" | cut -f1 -d.)"
            APT_SYSTEMCTL_START=true
            # Third-party keyrings became the preferred method of
            # installation in Debian 11 (Bullseye), which Kali switched
            # to in roughly 2021.x releases
            if [ "$YEAR" -lt 2021 ]; then
                # Kali VERSION_ID is "kali-rolling", which isn't distinguishing
                VERSION="buster"
                APT_KEY_TYPE="legacy"
            else
                VERSION="bullseye"
                APT_KEY_TYPE="keyring"
            fi
            ;;
        Deepin)  # https://github.com/tailscale/tailscale/issues/7862
            OS="debian"
            PACKAGETYPE="apt"
            if [ "$VERSION_ID" -lt 20 ]; then
                APT_KEY_TYPE="legacy"
            else
                APT_KEY_TYPE="keyring"
            fi
            ;;
        centos)
            OS="$ID"
            VERSION="$VERSION_ID"
            PACKAGETYPE="dnf"
            if [ "$VERSION" = "7" ]; then
                PACKAGETYPE="yum"
            fi
            ;;
        ol)
            OS="oracle"
            VERSION="$(echo "$VERSION_ID" | cut -f1 -d.)"
            PACKAGETYPE="dnf"
            if [ "$VERSION" = "7" ]; then
                PACKAGETYPE="yum"
            fi
            ;;
        rhel)
            OS="$ID"
            VERSION="$(echo "$VERSION_ID" | cut -f1 -d.)"
            PACKAGETYPE="dnf"
            if [ "$VERSION" = "7" ]; then
                PACKAGETYPE="yum"
            fi
            ;;
        fedora)
            OS="$ID"
            VERSION=""
            PACKAGETYPE="dnf"
            ;;
        rocky|almalinux|nobara|openmandriva|sangoma|risios)
            OS="fedora"
            VERSION=""
            PACKAGETYPE="dnf"
            ;;
        amzn)
            OS="amazon-linux"
            VERSION="$VERSION_ID"
            PACKAGETYPE="yum"
            ;;
        xenenterprise)
            OS="centos"
            VERSION="$(echo "$VERSION_ID" | cut -f1 -d.)"
            PACKAGETYPE="yum"
            ;;
        opensuse-leap|sles)
            OS="opensuse"
            VERSION="leap/$VERSION_ID"
            PACKAGETYPE="zypper"
            ;;
        opensuse-tumbleweed)
            OS="opensuse"
            VERSION="tumbleweed"
            PACKAGETYPE="zypper"
            ;;
        arch|archarm|endeavouros)
            OS="arch"
            VERSION="" # rolling release
            PACKAGETYPE="pacman"
            ;;
        manjaro|manjaro-arm)
            OS="manjaro"
            VERSION="" # rolling release
            PACKAGETYPE="pacman"
            ;;
        alpine)
            OS="$ID"
            VERSION="$VERSION_ID"
            PACKAGETYPE="apk"
            ;;
        postmarketos)
            OS="alpine"
            VERSION="$VERSION_ID"
            PACKAGETYPE="apk"
            ;;
        nixos)
            echo "Please add Tailscale to your NixOS configuration directly:"
            echo
            echo "services.tailscale.enable = true;"
            exit 1
            ;;
        void)
            OS="$ID"
            VERSION="" # rolling release
            PACKAGETYPE="xbps"
            ;;
        gentoo)
            OS="$ID"
            VERSION="" # rolling release
            PACKAGETYPE="emerge"
            ;;
        freebsd)
            OS="$ID"
            VERSION="$(echo "$VERSION_ID" | cut -f1 -d.)"
            PACKAGETYPE="pkg"
            ;;
        osmc)
            OS="debian"
            PACKAGETYPE="apt"
            VERSION="bullseye"
            APT_KEY_TYPE="keyring"
            ;;
        photon)
            OS="photon"
            VERSION="$(echo "$VERSION_ID" | cut -f1 -d.)"
            PACKAGETYPE="tdnf"
            ;;

        # TODO: wsl?
        # TODO: synology? qnap?
    esac
fi

# If we failed to detect something through os-release, consult
# uname and try to infer things from that.
if [ -z "$OS" ]; then
    if type uname >/dev/null 2>&1; then
        case "$(uname)" in
            FreeBSD)
                # FreeBSD before 12.2 doesn't have
                # /etc/os-release, so we wouldn't have found it in
                # the os-release probing above.
                OS="freebsd"
                VERSION="$(freebsd-version | cut -f1 -d.)"
                PACKAGETYPE="pkg"
                ;;
            OpenBSD)
                OS="openbsd"
                VERSION="$(uname -r)"
                PACKAGETYPE=""
                ;;
            Darwin)
                OS="macos"
                VERSION="$(sw_vers -productVersion | cut -f1-2 -d.)"
                PACKAGETYPE="appstore"
                ;;
            Linux)
                OS="other-linux"
                VERSION=""
                PACKAGETYPE=""
                ;;
        esac
    fi
fi

# Ideally we want to use curl, but on some installs we
# only have wget. Detect and use what's available.
CURL=
if type curl >/dev/null; then
    CURL="curl -fsSL"
elif type wget >/dev/null; then
    CURL="wget -q -O-"
fi
if [ -z "$CURL" ]; then
    echo "The installer needs either curl or wget to download files."
    echo "Please install either curl or wget to proceed."
    exit 1
fi

# Step 2: having detected an OS we support, is it one of the
# versions we support?
OS_UNSUPPORTED=
case "$OS" in
    ubuntu|debian|raspbian|centos|oracle|rhel|amazon-linux|opensuse|photon)
        # Check with the package server whether a given version is supported.
        URL="https://pkgs.tailscale.com/$TRACK/$OS/$VERSION/installer-supported"
        $CURL "$URL" 2> /dev/null | grep -q OK || OS_UNSUPPORTED=1
        ;;
    fedora)
        # All versions supported, no version checking required.
        ;;
    arch)
        # Rolling release, no version checking needed.
        ;;
    manjaro)
        # Rolling release, no version checking needed.
        ;;
    alpine)
        # All versions supported, no version checking needed.
        # TODO: is that true? When was tailscale packaged?
        ;;
    void)
        # Rolling release, no version checking needed.
        ;;
    gentoo)
        # Rolling release, no version checking needed.
        ;;
    freebsd)
        if [ "$VERSION" != "12" ] && \
           [ "$VERSION" != "13" ]
        then
            OS_UNSUPPORTED=1
        fi
        ;;
    openbsd)
        OS_UNSUPPORTED=1
        ;;
    macos)
        # We delegate macOS installation to the app store, it will
        # perform version checks for us.
        ;;
    other-linux)
        OS_UNSUPPORTED=1
        ;;
    *)
        OS_UNSUPPORTED=1
        ;;
esac
if [ "$OS_UNSUPPORTED" = "1" ]; then
    case "$OS" in
        other-linux)
            echo "Couldn't determine what kind of Linux is running."
            echo "You could try the static binaries at:"
            echo "https://pkgs.tailscale.com/$TRACK/#static"
            ;;
        "")
            echo "Couldn't determine what operating system you're running."
            ;;
        *)
            echo "$OS $VERSION isn't supported by this script yet."
            ;;
    esac
    echo
    echo "If you'd like us to support your system better, please email support@tailscale.com"
    echo "and tell us what OS you're running."
    echo
    echo "Please include the following information we gathered from your system:"
    echo
    echo "OS=$OS"
    echo "VERSION=$VERSION"
    echo "PACKAGETYPE=$PACKAGETYPE"
    if type uname >/dev/null 2>&1; then
        echo "UNAME=$(uname -a)"
    else
        echo "UNAME="
    fi
    echo
    if [ -f /etc/os-release ]; then
        cat /etc/os-release
    else
        echo "No /etc/os-release"
    fi
    exit 1
fi


echo os: $OS $VERSION $TRACK
echo package manger: $PACKAGETYPE
echo apt key type: $APT_KEY_TYPE
echo apt systemctl start: $APT_SYSTEMCTL_START
