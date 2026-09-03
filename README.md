# Asterisk RHEL Deployment

Reproducible Asterisk 22.10.1 deployment baseline for Red Hat Enterprise Linux.

The project is designed to provide a clean, minimal Asterisk installation that can be:

* Installed on a fresh RHEL server from GitHub.
* Used as a Master OVA.
* Cloned and customized.
* Verified automatically.
* Extended later without rebuilding the architecture.

---

# 1. Architecture

The project uses two deployment methods.

```text
                         GitHub
                           |
                 +---------+---------+
                 |                   |
                 v                   v
        Fresh RHEL Server       Master OVA
                 |                   |
                 v                   v
          ./install.sh            Clone
                 |                   |
                 v                   v
        Asterisk 22.10.1       Customize
                 |                   |
                 v                   v
       systemd + SELinux         Deploy
                 |
                 v
             verify.sh
```

GitHub is the reproducible source of truth.

The OVA is the fast VM deployment method.

---

# 2. Current Validated Master Baseline

Current reference Master:

```text
OS:                    RHEL 9.8
Architecture:          x86_64
Asterisk:              22.10.1
PJSIP:                 Enabled
SIP Transport:         UDP
SIP Bind:              0.0.0.0:5060
SELinux:               Enforcing
systemd:               asterisk.service
Module autoload:       Disabled
Echo extension:        600
```

Validated behavior:

```text
Asterisk starts automatically
PJSIP loads
UDP 5060 listens
SELinux remains Enforcing
No Asterisk startup ERROR
No Asterisk startup WARNING
No new Asterisk SELinux AVC
Asterisk reaches "Asterisk Ready."
```

---

# 3. Project Structure

The repository is intended to contain:

```text
asterisk-rhel-deployment/
|
├── README.md
├── VERSION
├── .gitignore
|
├── install.sh
├── build.sh
├── verify.sh
├── cleanup.sh
|
├── configs/
│   └── asterisk/
│       ├── asterisk.conf
│       ├── modules.conf
│       ├── pjsip.conf
│       ├── extensions.conf
│       ├── logger.conf
│       ├── stasis.conf
│       └── required core configuration files
|
├── patches/
│   └── asterisk-22.10.1-stasis-taskpool.patch
|
├── packages/
│   ├── common.sh
│   ├── rhel8.sh
│   └── rhel9.sh
|
├── selinux/
│   └── asterisk-local-net.te
|
├── systemd/
│   └── asterisk.service
|
└── docs/
```

---

# 4. Requirements

The target machine must have:

```text
RHEL 8 or RHEL 9
x86_64
root or sudo access
Internet access OR usable local package repositories
Git
GitHub access
```

RHEL repository access is required to install dependencies.

An unregistered RHEL system may not have access to all required Red Hat packages.

---

# 5. GitHub Authentication

A minimal RHEL server does NOT need a browser installed.

Use GitHub CLI device authentication.

Check:

```bash
git --version
gh --version
```

Authenticate:

```bash
gh auth login
```

Select:

```text
GitHub.com
HTTPS
Yes - Authenticate Git with your GitHub credentials
Login with a web browser
```

The server may display:

```text
First copy your one-time code: XXXX-XXXX
```

From another computer, open:

```text
https://github.com/login/device
```

Enter the temporary code.

Verify:

```bash
gh auth status
```

Configure Git:

```bash
gh auth setup-git
```

Verify again:

```bash
gh auth status
```

Do not place GitHub tokens, passwords, or credentials inside this repository.

---

# 6. Create a New GitHub Repository

Example repository:

```text
asterisk-rhel-deployment
```

Create local project:

```bash
mkdir -p /opt/asterisk-rhel-deployment
cd /opt/asterisk-rhel-deployment
```

Initialize Git:

```bash
git init
git branch -M main
```

Create GitHub repository:

```bash
gh repo create asterisk-rhel-deployment \
  --private \
  --source=. \
  --remote=origin
```

Check:

```bash
git remote -v
```

Expected:

```text
origin  https://github.com/YOUR_USERNAME/asterisk-rhel-deployment.git
```

The server does not need a graphical browser to perform the Git operations.

---

# 7. Git Identity

Configure the Git author.

```bash
git config --global user.name "YOUR NAME"
git config --global user.email "YOUR_GITHUB_EMAIL"
```

Verify:

```bash
git config --global user.name
git config --global user.email
```

---

# 8. Initial Git Workflow

Check files:

```bash
git status
```

Stage files:

```bash
git add .
```

Review:

```bash
git status
git diff --cached --stat
git diff --cached --name-only
```

Create commit:

```bash
git commit -m "Add Asterisk 22.10.1 RHEL deployment baseline"
```

Push:

```bash
git push -u origin main
```

Verify:

```bash
git status
```

Expected:

```text
nothing to commit, working tree clean
```

---

# 9. Asterisk Source

Asterisk is built from source rather than relying on a precompiled binary.

Current source:

```text
/usr/src/asterisk-22.10.1
```

Installed binary:

```text
/usr/sbin/asterisk
```

Check version:

```bash
asterisk -rx "core show version"
```

Expected:

```text
Asterisk 22.10.1
```

The destination server should compile Asterisk locally.

Do not rely on copying the RHEL 9 compiled binary to RHEL 8.

---

# 10. Source Patch

The current Asterisk 22.10.1 baseline contains one local Stasis source correction.

Patch:

```text
patches/asterisk-22.10.1-stasis-taskpool.patch
```

Change:

```c
static struct aco_type *taskpool_options[] =
        ACO_TYPES(&threadpool_option, &taskpool_option);
```

to:

```c
static struct aco_type *taskpool_options[] =
        ACO_TYPES(&taskpool_option);
```

This patch is version-specific.

The installer must:

1. Confirm the source version is 22.10.1.
2. Confirm the expected original line exists.
3. Apply the patch once.
4. Fail if the expected source does not match.

Never blindly patch an unrelated Asterisk version.

---

# 11. Building Asterisk

Manual build flow:

```bash
cd /usr/src/asterisk-22.10.1
```

Install source prerequisites using the selected RHEL dependency script.

Then configure:

```bash
./configure
```

Build:

```bash
make -j"$(nproc)"
```

Install:

```bash
make install
```

Update libraries:

```bash
ldconfig
```

Verify:

```bash
asterisk -rx "core show version"
```

The future `build.sh` script will automate these steps.

---

# 12. Asterisk Configuration

Active configuration directory:

```text
/etc/asterisk
```

Important files:

```text
asterisk.conf
modules.conf
pjsip.conf
extensions.conf
logger.conf
stasis.conf
```

Required core configuration files are also included where Asterisk expects them.

Configuration must come from the matching Asterisk version.

Do not mix configuration files from unrelated Asterisk releases.

---

# 13. Asterisk Main Configuration

Current directories:

```text
astetcdir      /etc/asterisk
astmoddir      /usr/lib/asterisk/modules
astvarlibdir   /var/lib/asterisk
astdbdir       /var/lib/asterisk
astrundir      /var/run/asterisk
astlogdir      /var/log/asterisk
astsbindir     /usr/sbin
```

Verify:

```bash
cat /etc/asterisk/asterisk.conf
```

---

# 14. Module Loading

The Master uses:

```ini
[modules]
autoload=no
```

This prevents unnecessary automatic loading.

The baseline explicitly loads required modules for:

```text
PBX
PJSIP
RTP
basic codecs
Echo
```

It explicitly disables:

```text
chan_unistim.so
res_stun_monitor.so
```

Verify:

```bash
cat /etc/asterisk/modules.conf
```

Check loaded modules:

```bash
asterisk -rx "module show"
```

Check PJSIP:

```bash
asterisk -rx "module show like pjsip"
```

---

# 15. PJSIP

Current transport:

```ini
[transport-udp]
type=transport
protocol=udp
bind=0.0.0.0:5060
```

Verify:

```bash
asterisk -rx "pjsip show transports"
```

Expected:

```text
transport-udp    udp    0.0.0.0:5060
```

Verify operating-system port:

```bash
ss -lunp | grep ':5060'
```

Expected:

```text
0.0.0.0:5060
```

The Master does not contain customer SIP endpoints or trunks.

Those are added during customization.

---

# 16. Dialplan

Current Master includes a simple Echo test.

```ini
[general]
static=yes
writeprotect=no
autofallthrough=yes

[default]
exten => 600,1,Answer()
 same => n,Echo()
 same => n,Hangup()
```

Extension:

```text
600
```

Purpose:

```text
PJSIP registration/call testing
Dialplan testing
RTP/audio testing
```

Verify:

```bash
asterisk -rx "dialplan show 600@default"
```

---

# 17. Stasis

The final baseline uses an empty:

```text
/etc/asterisk/stasis.conf
```

The file exists but contains no custom taskpool settings.

The Asterisk source patch fixes the problematic configuration registration.

Do not add arbitrary taskpool options to this file.

Verify:

```bash
ls -l /etc/asterisk/stasis.conf
```

---

# 18. Logging

Current logging configuration:

```text
/etc/asterisk/logger.conf
```

Verify:

```bash
cat /etc/asterisk/logger.conf
```

Check startup:

```bash
journalctl -u asterisk -b --no-pager
```

---

# 19. systemd

Service:

```text
/etc/systemd/system/asterisk.service
```

Current service runs Asterisk in the foreground:

```text
Type=simple
ExecStart=/usr/sbin/asterisk -f
```

This is intentional.

Check:

```bash
systemctl status asterisk --no-pager -l
```

Enable:

```bash
systemctl enable asterisk
```

Start:

```bash
systemctl start asterisk
```

Restart:

```bash
systemctl restart asterisk
```

Stop:

```bash
systemctl stop asterisk
```

Verify:

```bash
systemctl is-enabled asterisk
systemctl is-active asterisk
```

Expected:

```text
enabled
active
```

---

# 20. SELinux

SELinux must remain:

```text
Enforcing
```

Verify:

```bash
getenforce
```

Do NOT disable SELinux.

Do not use:

```bash
setenforce 0
```

as a permanent solution.

---

# 21. Asterisk SELinux File Contexts

Required directories:

```text
/var/lib/asterisk
/var/log/asterisk
/var/spool/asterisk
```

Expected types:

```text
asterisk_var_lib_t
asterisk_log_t
asterisk_spool_t
```

Restore contexts:

```bash
restorecon -RFv /etc/asterisk
restorecon -RFv /var/lib/asterisk
restorecon -RFv /var/log/asterisk
restorecon -RFv /var/spool/asterisk
```

Verify:

```bash
ls -Zd /var/lib/asterisk
ls -Zd /var/log/asterisk
ls -Zd /var/spool/asterisk
```

---

# 22. Local SELinux Policy

The Master requires one small local SELinux rule.

Source:

```text
selinux/asterisk-local-net.te
```

Contents:

```te
module asterisk_local_net 1.0;

require {
    type asterisk_t;
    type sysctl_net_t;
    class dir search;
}

allow asterisk_t sysctl_net_t:dir search;
```

Purpose:

```text
asterisk_t
    |
    +---- search
             |
             v
       sysctl_net_t
```

This allows the specific operation required by Asterisk's network Entity ID detection.

It does not disable SELinux.

---

# 23. Compile SELinux Module

Required commands:

```bash
checkmodule -M -m \
  -o asterisk_local_net.mod \
  selinux/asterisk-local-net.te
```

Create package:

```bash
semodule_package \
  -o asterisk_local_net.pp \
  -m asterisk_local_net.mod
```

Install:

```bash
semodule -i asterisk_local_net.pp
```

Verify:

```bash
semodule -l | grep -i asterisk
```

The local module should appear as:

```text
asterisk_local_net
```

Verify policy:

```bash
sesearch -A \
  -s asterisk_t \
  -t sysctl_net_t \
  -c dir \
  -p search
```

Expected:

```text
allow asterisk_t sysctl_net_t:dir search;
```

---

# 24. SELinux AVC Verification

Check recent AVCs:

```bash
ausearch -m AVC -ts recent -c asterisk -i
```

Check specifically:

```bash
ausearch -m AVC -ts recent -c asterisk -i \
 | grep 'name=net'
```

Expected:

```text
no output
```

Important:

The audit system may contain older AVC records.

Old records do not prove that a new restart failed.

Always test after the latest Asterisk restart.

---

# 25. Clean Startup Verification

Restart:

```bash
systemctl restart asterisk
sleep 3
```

Check:

```bash
journalctl -u asterisk --since "10 seconds ago" --no-pager
```

Check for startup errors/warnings:

```bash
journalctl -u asterisk --since "10 seconds ago" --no-pager \
 | grep -iE 'ERROR|WARNING|failed|Unable to load|Asterisk Ready' || true
```

Expected:

```text
Asterisk Ready.
```

and no:

```text
ERROR
WARNING
failed
Unable to load
```

---

# 26. Complete Verification

Run:

```bash
asterisk -rx "core show version"

asterisk -rx "module show like pjsip"

asterisk -rx "pjsip show transports"

ss -lunp | grep ':5060'

getenforce

systemctl is-enabled asterisk

systemctl is-active asterisk
```

Then:

```bash
journalctl -u asterisk --since "10 seconds ago" --no-pager \
 | grep -iE 'ERROR|WARNING|failed|Unable to load|Asterisk Ready' || true
```

Then:

```bash
ausearch -m AVC -ts recent -c asterisk -i \
 | grep 'name=net' || true
```

A successful deployment should result in:

```text
Asterisk 22.10.1
PJSIP modules Running
transport-udp 0.0.0.0:5060
5060 listening
Enforcing
enabled
active
Asterisk Ready.
No startup ERROR
No startup WARNING
No new Asterisk AVC
```

---

# 27. One-Command Installation

The final target is:

```bash
git clone https://github.com/Omkar7039/asterisk-rhel-deployment.git
cd asterisk-rhel-deployment
sudo ./install.sh
```

For root:

```bash
git clone https://github.com/Omkar7039/asterisk-rhel-deployment.git
cd asterisk-rhel-deployment
./install.sh
```

The installer should automatically:

```text
detect RHEL
detect RHEL major version
check repositories
install dependencies
download Asterisk 22.10.1
verify source
apply the Stasis patch
compile Asterisk
install Asterisk
install configuration
install systemd
install SELinux policy
restore SELinux contexts
enable Asterisk
start Asterisk
run verification
report PASS/FAIL
```

---

# 28. RHEL Version Detection

The installer can detect the major version with:

```bash
rpm -E %{rhel}
```

Expected:

```text
8
```

or:

```text
9
```

Use separate package logic:

```text
packages/rhel8.sh
packages/rhel9.sh
```

Do not assume the dependency package names are identical on all RHEL releases.

---

# 29. Repository Availability

The installer must verify that repositories are usable before attempting the build.

Example test:

```bash
dnf repolist
```

If package repositories are unavailable, the installer should stop with a clear error.

The project must not silently continue with missing build dependencies.

---

# 30. Configuration Safety

Never commit:

```text
passwords
SIP credentials
API keys
tokens
private keys
TLS private keys
customer credentials
machine-id
SSH host keys
```

Search before committing:

```bash
grep -RniE \
'password|secret|token|api[_-]?key|private[_-]?key|BEGIN .* PRIVATE KEY' \
. \
2>/dev/null || true
```

Review the output manually.

Comments containing example words such as `password = mysecret` are not credentials, but real credentials must never be committed.

---

# 31. Files That Must Not Be in GitHub

Do not commit:

```text
/var/log/asterisk/*
/var/run/asterisk/*
/var/lib/asterisk/astdb.sqlite3
/var/spool/asterisk/outgoing/*
/etc/machine-id
/etc/ssh/ssh_host_*
*.ova
*.vmdk
*.iso
*.tar.gz
compiled binaries
temporary build files
private keys
customer secrets
```

Git ignores these through `.gitignore` where appropriate.

---

# 32. Customization

The Master provides only a clean baseline.

After deployment/clone, add:

```text
SIP endpoints
SIP authentication
trunks
dialplan
extensions
NAT
TLS
customer settings
CDR integrations
monitoring
firewall requirements
external systems
```

Do not put customer-specific credentials into the Master baseline.

---

# 33. Clone Customization Model

Recommended flow:

```text
Master OVA
    |
    v
Clone VM
    |
    +---- new machine identity
    +---- new SSH host keys
    +---- new VM network identity
    |
    v
Customize Asterisk
    |
    v
Test
    |
    v
Deploy
```

The Master should remain unchanged.

---

# 34. Machine Identity

A Master OVA must not be distributed with the same machine identity.

Before final OVA export:

```bash
rm -f /etc/machine-id
rm -f /var/lib/dbus/machine-id
touch /etc/machine-id
```

Do not permanently hard-code the Master machine ID into deployment files.

After the clone boots, verify:

```bash
cat /etc/machine-id
```

The clone should have its own machine identity.

---

# 35. SSH Host Keys

Before exporting the Master OVA:

```bash
rm -f /etc/ssh/ssh_host_*
```

The cloned machine should generate its own SSH host keys during boot.

Never commit SSH host keys to GitHub.

---

# 36. Asterisk Runtime Cleanup

Before final OVA export:

```bash
systemctl stop asterisk
```

Remove runtime logs:

```bash
rm -f /var/log/asterisk/*
```

Remove outgoing runtime files:

```bash
rm -f /var/spool/asterisk/outgoing/*
```

Reset the Asterisk database if the Master is intended to be a clean template:

```bash
rm -f /var/lib/asterisk/astdb.sqlite3
```

Restore contexts:

```bash
restorecon -RFv /var/lib/asterisk
restorecon -RFv /var/log/asterisk
restorecon -RFv /var/spool/asterisk
```

---

# 37. System Journal Cleanup

Rotate:

```bash
journalctl --rotate
```

Vacuum:

```bash
journalctl --vacuum-time=1s
```

This prevents the Master OVA from carrying unnecessary historical logs.

---

# 38. Shell History Cleanup

Before export:

```bash
rm -f /root/.bash_history
history -c
```

Do not store secrets in shell history.

---

# 39. Final OVA Shutdown

After cleanup:

```bash
sync
shutdown -h now
```

Do not make more changes after the final shutdown.

---

# 40. OVA Export

In VMware Workstation:

```text
Power off VM
   ↓
Select VM
   ↓
Manage
   ↓
Export
   ↓
OVA
```

The resulting OVA is the deployment template.

---

# 41. OVA Clone Test

Do not immediately consider the OVA production-ready.

Deploy one test clone.

After boot:

```bash
hostnamectl
cat /etc/machine-id
systemctl is-enabled asterisk
systemctl is-active asterisk
```

Then:

```bash
asterisk -rx "core show version"
asterisk -rx "pjsip show transports"
ss -lunp | grep ':5060'
getenforce
```

Then:

```bash
journalctl -u asterisk -b --no-pager \
 | grep -iE 'ERROR|WARNING|failed|Unable to load|Asterisk Ready' || true
```

Then:

```bash
ausearch -m AVC -ts recent -c asterisk -i \
 | grep 'name=net' || true
```

Only after this test passes should the OVA be considered a validated deployment template.

---

# 42. Git Versioning

Repository release:

```text
v1.0.0
```

Create tag:

```bash
git tag v1.0.0
git push origin v1.0.0
```

Check:

```bash
git tag
```

Future releases:

```text
v1.1.0
v1.2.0
v2.0.0
```

Do not silently replace a known-good Asterisk version.

---

# 43. Reproducible Deployment

To reproduce the known release:

```bash
git clone https://github.com/Omkar7039/asterisk-rhel-deployment.git
cd asterisk-rhel-deployment
git checkout v1.0.0
./install.sh
```

This ensures the exact repository release is used.

Do not use an untested `main` branch for production deployments if a tagged version is available.

---

# 44. Update Workflow

When changing the project:

```bash
git status
```

Review changes:

```bash
git diff
```

Stage:

```bash
git add .
```

Review staged changes:

```bash
git diff --cached
```

Commit:

```bash
git commit -m "Describe the change"
```

Push:

```bash
git push
```

---

# 45. Pulling Updates

For a development machine:

```bash
git pull --ff-only
```

Check:

```bash
git status
```

For production, prefer a tested tag:

```bash
git fetch --tags
git checkout v1.0.0
```

---

# 46. Upgrade Strategy

Do not automatically upgrade Asterisk just because a newer version exists.

Upgrade process:

```text
Current known-good version
        |
        v
Create new branch
        |
        v
Change Asterisk version
        |
        v
Update source patch if required
        |
        v
Build
        |
        v
Fresh RHEL 9 test
        |
        v
Fresh RHEL 8 test
        |
        v
Functional test
        |
        v
SELinux test
        |
        v
OVA clone test
        |
        v
New release tag
```

Example:

```text
v1.0.0 → Asterisk 22.10.1
v2.0.0 → future tested Asterisk release
```

Keep the old version available.

---

# 47. Future Features

The repository can later add:

```text
Endpoint templates
SIP trunk templates
TLS
firewall configuration
automatic certificate deployment
CDR integrations
monitoring
health checks
backup/restore
database integrations
HA configuration
customer profiles
multi-site deployment
```

The base architecture should remain stable.

---

# 48. Future Customization Profiles

Possible future structure:

```text
profiles/
├── base/
├── lab/
├── production/
├── customer-a/
└── customer-b/
```

A profile can define:

```text
endpoints
trunks
dialplan
codecs
TLS
network settings
monitoring
```

The base remains unchanged.

---

# 49. Future Automated Verification

`verify.sh` should eventually return:

```text
PASS
```

only when all required tests succeed.

Example checks:

```text
OS supported
RHEL version supported
Asterisk binary exists
Asterisk version correct
systemd service exists
systemd enabled
systemd active
PJSIP loaded
PJSIP transport exists
UDP 5060 listening
SELinux Enforcing
required SELinux contexts correct
SELinux module installed
no new Asterisk AVC
no startup ERROR
no startup WARNING
dialplan 600 exists
Asterisk Ready
```

A failure should return a non-zero shell exit status.

---

# 50. Troubleshooting

## Asterisk is not running

```bash
systemctl status asterisk --no-pager -l
```

Check:

```bash
journalctl -u asterisk -b --no-pager
```

---

## PJSIP is not loaded

```bash
asterisk -rx "module show like pjsip"
```

Then:

```bash
cat /etc/asterisk/modules.conf
```

---

## UDP 5060 is not listening

```bash
asterisk -rx "pjsip show transports"
ss -lunp | grep ':5060'
```

---

## SELinux denial

Check:

```bash
ausearch -m AVC -ts recent -c asterisk -i
```

Look specifically for:

```text
name=net
```

Check installed policy:

```bash
semodule -l | grep -i asterisk
```

Check rule:

```bash
sesearch -A \
  -s asterisk_t \
  -t sysctl_net_t \
  -c dir \
  -p search
```

Do not disable SELinux just to hide the problem.

---

## Asterisk reports configuration errors

Check:

```bash
journalctl -u asterisk --since "10 seconds ago" --no-pager
```

Check:

```bash
ls -la /etc/asterisk
```

Never copy random configuration files from a different Asterisk version.

---

# 51. Design Rules

The project follows these principles:

```text
Minimal base
Reproducible builds
Version pinning
SELinux enabled
No secrets in GitHub
No VM-specific identity in the Master
No customer settings in the Master
No untested upgrades
Automatic verification
```

---

# 52. Golden Rule

Do not modify the validated Master just because one customer requires something special.

Use:

```text
Master
   |
   +---- Clone A → Customer A
   |
   +---- Clone B → Customer B
   |
   +---- Clone C → Lab
```

The Master remains the clean baseline.

---

# 53. Final Deployment Model

```text
                         GitHub
                           |
             +-------------+-------------+
             |                           |
             v                           v
        Fresh RHEL                    Master OVA
             |                           |
             v                           v
        ./install.sh                  Clone
             |                           |
             v                           v
      Asterisk 22.10.1             Customize
             |                           |
             +------------+--------------+
                          |
                          v
                       Verify
                          |
                          v
                       Deploy
```

---

# 54. Current Status

Current validated baseline:

```text
RHEL 9.8                    PASS
Asterisk 22.10.1            PASS
PJSIP                       PASS
UDP 5060                    PASS
systemd                     PASS
SELinux Enforcing           PASS
SELinux AVC                 PASS
Clean startup               PASS
Asterisk Ready              PASS
```

Repository baseline:

```text
GitHub repository           PASS
README                      PASS
Asterisk configuration      PASS
systemd service             PASS
SELinux source              PASS
Stasis patch                PASS
```

Automation:

```text
install.sh                  IN DEVELOPMENT
build.sh                    IN DEVELOPMENT
verify.sh                   IN DEVELOPMENT
cleanup.sh                  IN DEVELOPMENT
RHEL 9 fresh install test   REQUIRED
RHEL 8 fresh install test   REQUIRED
OVA clone test              REQUIRED
v1.0.0 release              PENDING
```

---

# 55. Final Goal

A new administrator should eventually be able to perform:

```bash
git clone https://github.com/Omkar7039/asterisk-rhel-deployment.git
cd asterisk-rhel-deployment
git checkout v1.0.0
./install.sh
```

and receive a fully configured, SELinux-enabled, systemd-managed Asterisk installation.

The same validated baseline should also be available as:

```text
Master OVA
    ↓
Clone
    ↓
Customize
    ↓
Deploy
```

GitHub provides reproducibility.

The OVA provides speed.

The Master provides a clean baseline.

The clone provides the customization target.

