#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ASTERISK_VERSION_DEFAULT="22.10.1"
SIP_BIND_DEFAULT="0.0.0.0"
SIP_PORT_DEFAULT="5060"

SOURCE_BASE_URL="https://downloads.asterisk.org/pub/telephony/asterisk/releases"

AST_SRC_DIR="/usr/src/asterisk"
AST_INSTALL_USER="root"
AST_INSTALL_GROUP="root"

ASTERISK_ETC="/etc/asterisk"
SYSTEMD_FILE="/etc/systemd/system/asterisk.service"

CONFIG_DIR="$REPO_DIR/configs/asterisk"
PATCH_FILE="$REPO_DIR/patches/asterisk-22.10.1-stasis-taskpool.patch"
SELINUX_TE="$REPO_DIR/selinux/asterisk-local-net.te"

DEFAULTS=false
ASTERISK_VERSION="$ASTERISK_VERSION_DEFAULT"
SIP_BIND="$SIP_BIND_DEFAULT"
SIP_PORT="$SIP_PORT_DEFAULT"
INSTALL_SELINUX=true
INSTALL_SYSTEMD=true
START_ASTERISK=true

log() {
    printf '\n[%s] %s\n' "$(date '+%F %T')" "$*"
}

die() {
    printf '\nERROR: %s\n' "$*" >&2
    exit 1
}

cleanup() {
    rm -f /tmp/asterisk-install-prereq.log \
          /tmp/asterisk-install-build.log \
          /tmp/asterisk-install-test.log
}
trap cleanup EXIT

usage() {
    cat <<'USAGE'
Usage:
  ./install.sh
  ./install.sh --defaults
  ./install.sh --version 22.10.1
  ./install.sh --bind 0.0.0.0
  ./install.sh --port 5060
  ./install.sh --help

Options:
  --defaults           Use standard defaults and ask no questions.
  --version VERSION    Asterisk version. Default: 22.10.1
  --bind ADDRESS       PJSIP bind address. Default: 0.0.0.0
  --port PORT          PJSIP UDP port. Default: 5060
  --help               Show this help.
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --defaults)
            DEFAULTS=true
            shift
            ;;
        --version)
            [[ $# -ge 2 ]] || die "--version requires a value"
            ASTERISK_VERSION="$2"
            shift 2
            ;;
        --bind)
            [[ $# -ge 2 ]] || die "--bind requires a value"
            SIP_BIND="$2"
            shift 2
            ;;
        --port)
            [[ $# -ge 2 ]] || die "--port requires a value"
            SIP_PORT="$2"
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            die "Unknown option: $1"
            ;;
    esac
done

[[ $EUID -eq 0 ]] || die "Run this installer as root."

command -v dnf >/dev/null 2>&1 || die "dnf is required."
command -v curl >/dev/null 2>&1 || die "curl is required."
command -v tar >/dev/null 2>&1 || die "tar is required."
command -v patch >/dev/null 2>&1 || die "patch is required."

log "Asterisk RHEL Deployment"
log "Repository: $REPO_DIR"

if [[ -f /etc/redhat-release ]]; then
    RHEL_MAJOR="$(rpm -E '%{rhel}')"
else
    die "This installer supports RHEL only."
fi

case "$RHEL_MAJOR" in
    8|9)
        log "Detected RHEL $RHEL_MAJOR"
        ;;
    *)
        die "Unsupported RHEL major version: $RHEL_MAJOR"
        ;;
esac

if [[ ! -d "$CONFIG_DIR" ]]; then
    die "Missing configuration directory: $CONFIG_DIR"
fi

if [[ ! -f "$PATCH_FILE" ]]; then
    die "Missing Asterisk patch: $PATCH_FILE"
fi

if [[ ! -f "$SELINUX_TE" ]]; then
    die "Missing SELinux policy source: $SELINUX_TE"
fi

if [[ "$DEFAULTS" == false ]]; then
    read -r -p "Asterisk version [$ASTERISK_VERSION]: " INPUT
    ASTERISK_VERSION="${INPUT:-$ASTERISK_VERSION}"

    read -r -p "PJSIP bind address [$SIP_BIND]: " INPUT
    SIP_BIND="${INPUT:-$SIP_BIND}"

    read -r -p "PJSIP UDP port [$SIP_PORT]: " INPUT
    SIP_PORT="${INPUT:-$SIP_PORT}"

    read -r -p "Install SELinux policy? [Y/n]: " INPUT
    case "${INPUT:-Y}" in
        [Nn]*) INSTALL_SELINUX=false ;;
        *)     INSTALL_SELINUX=true ;;
    esac

    read -r -p "Install systemd service? [Y/n]: " INPUT
    case "${INPUT:-Y}" in
        [Nn]*) INSTALL_SYSTEMD=false ;;
        *)     INSTALL_SYSTEMD=true ;;
    esac

    read -r -p "Start Asterisk after installation? [Y/n]: " INPUT
    case "${INPUT:-Y}" in
        [Nn]*) START_ASTERISK=false ;;
        *)     START_ASTERISK=true ;;
    esac
fi

case "$ASTERISK_VERSION" in
    22.10.1)
        ;;
    *)
        die "This repository currently contains a patch specifically for Asterisk 22.10.1. Use --version 22.10.1."
        ;;
esac

[[ "$SIP_PORT" =~ ^[0-9]+$ ]] || die "Invalid SIP port: $SIP_PORT"
(( SIP_PORT >= 1 && SIP_PORT <= 65535 )) || die "SIP port must be 1-65535."

echo
echo "========================================"
echo " Installation Settings"
echo "========================================"
echo "RHEL version        : $RHEL_MAJOR"
echo "Asterisk version    : $ASTERISK_VERSION"
echo "PJSIP bind          : $SIP_BIND"
echo "PJSIP UDP port      : $SIP_PORT"
echo "SELinux policy      : $INSTALL_SELINUX"
echo "systemd service     : $INSTALL_SYSTEMD"
echo "Start Asterisk      : $START_ASTERISK"
echo "========================================"
echo

if [[ "$DEFAULTS" == false ]]; then
    read -r -p "Proceed with installation? [Y/n]: " INPUT
    case "${INPUT:-Y}" in
        [Nn]*) log "Installation cancelled."; exit 0 ;;
    esac
fi

log "[1/10] Checking package repositories"
dnf repolist >/dev/null || die "DNF repositories are not usable."

log "[2/10] Installing base tools"
dnf install -y \
    curl \
    wget \
    git \
    tar \
    gzip \
    patch \
    make \
    gcc \
    gcc-c++ \
    autoconf \
    automake \
    bison \
    flex \
    pkgconfig \
    diffutils \
    which \
    findutils \
    ncurses-devel \
    openssl-devel \
    libxml2-devel \
    sqlite-devel \
    libuuid-devel \
    jansson-devel \
    libedit-devel \
    python3 \
    python3-devel \
    policycoreutils \
    policycoreutils-python-utils \
    checkpolicy \
    policycoreutils-devel \
    >/tmp/asterisk-install-prereq.log 2>&1 \
    || die "Base dependency installation failed. See /tmp/asterisk-install-prereq.log"

log "[3/10] Downloading Asterisk $ASTERISK_VERSION"

mkdir -p /usr/src
ARCHIVE="/usr/src/asterisk-${ASTERISK_VERSION}.tar.gz"
CHECKSUM="/usr/src/asterisk-${ASTERISK_VERSION}.sha256"
SRC_DIR="/usr/src/asterisk-${ASTERISK_VERSION}"

curl -fL \
    -o "$ARCHIVE" \
    "$SOURCE_BASE_URL/asterisk-${ASTERISK_VERSION}.tar.gz" \
    || die "Asterisk source download failed."

curl -fL \
    -o "$CHECKSUM" \
    "$SOURCE_BASE_URL/asterisk-${ASTERISK_VERSION}.sha256" \
    || die "Asterisk SHA256 download failed."

(
    cd /usr/src
    sha256sum -c "$(basename "$CHECKSUM")"
) || die "Asterisk source checksum verification failed."

log "[4/10] Extracting Asterisk source"

rm -rf "$SRC_DIR"
tar -xzf "$ARCHIVE" -C /usr/src
[[ -d "$SRC_DIR" ]] || die "Source directory was not created."

cd "$SRC_DIR"

log "[5/10] Installing source prerequisites"

./contrib/scripts/install_prereq install \
    >/tmp/asterisk-install-prereq.log 2>&1 \
    || die "Asterisk install_prereq failed. See /tmp/asterisk-install-prereq.log"

log "[6/10] Applying Asterisk 22.10.1 Stasis patch"

if grep -Fq \
    'static struct aco_type *taskpool_options[] = ACO_TYPES(&threadpool_option, &taskpool_option);' \
    main/stasis.c; then

    patch -p1 < "$PATCH_FILE" \
        || die "Failed to apply Stasis patch."

elif grep -Fq \
    'static struct aco_type *taskpool_options[] = ACO_TYPES(&taskpool_option);' \
    main/stasis.c; then

    log "Stasis patch is already applied."

else
    die "Expected Asterisk 22.10.1 Stasis source line was not found."
fi

log "[7/10] Configuring Asterisk"

./configure \
    || die "Asterisk configure failed."

log "[8/10] Building Asterisk"

make -j"$(nproc)" \
    >/tmp/asterisk-install-build.log 2>&1 \
    || {
        tail -100 /tmp/asterisk-install-build.log
        die "Asterisk build failed."
    }

make install \
    >/tmp/asterisk-install-build.log 2>&1 \
    || {
        tail -100 /tmp/asterisk-install-build.log
        die "Asterisk installation failed."
    }

ldconfig

log "[9/10] Installing configuration"

mkdir -p \
    /etc/asterisk \
    /var/lib/asterisk \
    /var/log/asterisk \
    /var/spool/asterisk \
    /var/run/asterisk

if [[ -f "$ASTERISK_ETC/pjsip.conf" ]]; then
    BACKUP_DIR="/var/backups/asterisk/backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    cp -a "$ASTERISK_ETC/." "$BACKUP_DIR/"
    log "Existing Asterisk configuration backed up to $BACKUP_DIR"
fi

cp -af "$CONFIG_DIR/." "$ASTERISK_ETC/"

cat > "$ASTERISK_ETC/pjsip.conf" <<PJSIP
[transport-udp]
type=transport
protocol=udp
bind=${SIP_BIND}:${SIP_PORT}
PJSIP

: > "$ASTERISK_ETC/stasis.conf"

restorecon -RFv \
    "$ASTERISK_ETC" \
    /var/lib/asterisk \
    /var/log/asterisk \
    /var/spool/asterisk \
    >/dev/null 2>&1 || true

if [[ "$INSTALL_SELINUX" == true ]]; then
    log "[10/10] Installing SELinux policy"

    SELINUX_NAME="asterisk_local_net"
    SELINUX_BUILD_DIR="/tmp/asterisk-selinux"

    rm -rf "$SELINUX_BUILD_DIR"
    mkdir -p "$SELINUX_BUILD_DIR"

    cp "$SELINUX_TE" \
       "$SELINUX_BUILD_DIR/asterisk_local_net.te"

    checkmodule -M -m \
        -o "$SELINUX_BUILD_DIR/asterisk_local_net.mod" \
        "$SELINUX_BUILD_DIR/asterisk_local_net.te" \
        || die "SELinux checkmodule failed."

    semodule_package \
        -o "$SELINUX_BUILD_DIR/asterisk_local_net.pp" \
        -m "$SELINUX_BUILD_DIR/asterisk_local_net.mod" \
        || die "SELinux semodule_package failed."

    semodule -i \
        "$SELINUX_BUILD_DIR/asterisk_local_net.pp" \
        || die "SELinux module installation failed."
fi

if [[ "$INSTALL_SYSTEMD" == true ]]; then
    log "Installing systemd service"

    [[ -f "$REPO_DIR/systemd/asterisk.service" ]] \
        || die "Missing systemd service file."

    cp -f \
        "$REPO_DIR/systemd/asterisk.service" \
        "$SYSTEMD_FILE"

    systemctl daemon-reload

    if ! systemctl enable asterisk >/tmp/asterisk-systemd-enable.log 2>&1; then
        mkdir -p /etc/systemd/system/multi-user.target.wants
        ln -sf \
            "$SYSTEMD_FILE" \
            /etc/systemd/system/multi-user.target.wants/asterisk.service

        systemctl daemon-reload
    fi
fi

if [[ "$START_ASTERISK" == true ]]; then
    log "Starting Asterisk"

    systemctl restart asterisk \
        || die "Asterisk failed to start."

    sleep 3
fi

log "Running verification"

if [[ -x "$REPO_DIR/verify.sh" ]]; then
    "$REPO_DIR/verify.sh" \
        || die "Verification failed."
else
    systemctl is-active --quiet asterisk \
        || die "Asterisk service is not active."

    asterisk -rx "core show version" >/dev/null \
        || die "Asterisk CLI check failed."

    asterisk -rx "pjsip show transports" \
        | grep -Fq "${SIP_BIND}:${SIP_PORT}" \
        || die "PJSIP transport check failed."

    ss -lun \
        | grep -Fq ":${SIP_PORT}" \
        || die "UDP ${SIP_PORT} is not listening."
fi

echo
echo "========================================"
echo " Asterisk Installation Complete"
echo "========================================"
echo "RHEL               : $RHEL_MAJOR"
echo "Asterisk            : $ASTERISK_VERSION"
echo "PJSIP bind          : $SIP_BIND"
echo "PJSIP UDP port      : $SIP_PORT"
echo "SELinux             : $(getenforce)"
echo "systemd             : $(systemctl is-active asterisk 2>/dev/null || true)"
echo
echo "Asterisk version:"
asterisk -rx "core show version" | head -1
echo
echo "PJSIP transport:"
asterisk -rx "pjsip show transports"
echo
echo "Installation completed successfully."
echo "========================================"
