# Asterisk RHEL Deployment

Reproducible Asterisk 22.10.1 deployment for RHEL 8 and RHEL 9.

## Baseline

- Asterisk 22.10.1
- PJSIP
- UDP 5060
- SELinux Enforcing
- systemd
- Minimal module configuration
- Minimal dialplan
- Echo test extension 600

## Deployment model

GitHub is the source of truth for building a fresh installation.

OVA is intended for fast VM deployment.

## Target flow

RHEL 8/9
→ dependency installation
→ Asterisk source build
→ configuration
→ SELinux
→ systemd
→ verification

## Verification

The deployment must verify:

- Asterisk version
- systemd service
- PJSIP
- UDP 5060
- SELinux enforcing
- clean Asterisk startup
- no startup ERROR/WARNING
- no Asterisk SELinux AVC for /proc/sys/net
