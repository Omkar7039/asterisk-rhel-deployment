# Asterisk RHEL Deployment

Reproducible Asterisk 22.10.1 deployment baseline for Red Hat Enterprise Linux.

This project provides:

- Asterisk 22.10.1 from source
- PJSIP
- UDP SIP transport
- Minimal module loading
- Minimal Echo test dialplan
- SELinux Enforcing support
- Local SELinux policy
- Asterisk 22.10.1 Stasis source patch
- systemd service
- Automated installation
- Automated verification
- GitHub source-controlled configuration
- Version-controlled deployment
- Repeatable RHEL installation

---

# 1. PROJECT GOAL

The purpose of this project is to create a clean, reproducible and validated Asterisk installation on Red Hat Enterprise Linux.

The project is designed around GitHub as the single source of truth.

Deployment flow:

```text
                         GitHub
                            |
                            v
                     Fresh RHEL Server
                            |
                            v
                     ./install.sh
                            |
                            v
                    Asterisk 22.10.1
                            |
                            v
                     ./verify.sh
                            |
                            v
                    Working Asterisk




2. GITHUB SOURCE OF TRUTH

GitHub is the authoritative source for this project.

Repository:

https://github.com/Omkar7039/asterisk-rhel-deployment.git

GitHub stores:

README.md
VERSION
configs/
patches/
selinux/
systemd/
install.sh
verify.sh
build.sh
cleanup.sh

The server installation should be reproducible from the GitHub repository.

3. TARGET OPERATING SYSTEM

Primary target platforms:

Red Hat Enterprise Linux 8
Red Hat Enterprise Linux 9

Each major RHEL version must be tested separately.

The project should not claim support for an untested RHEL release.

4. REFERENCE ENVIRONMENT

Validated baseline:

Operating System : RHEL 9.8
Architecture     : x86_64
Hypervisor       : VMware
Asterisk         : 22.10.1
PJSIP            : Enabled
SELinux          : Enforcing
systemd          : Enabled
SIP Transport    : UDP
SIP Port         : 5060
5. ASTERISK VERSION

Current project baseline:

Asterisk 22.10.1

Source directory:

/usr/src/asterisk-22.10.1

Installed binary:

/usr/sbin/asterisk
6. ASTERISK SOURCE INSTALLATION

Asterisk is compiled from source.

Installation flow:

Download source
      |
      v
Verify checksum
      |
      v
Install prerequisites
      |
      v
Apply project patch
      |
      v
Configure
      |
      v
Compile
      |
      v
Install
7. SOURCE DIRECTORY

The baseline source directory is:

/usr/src/asterisk-22.10.1

Check:

ls -ld /usr/src/asterisk-22.10.1
8. ASTERISK BINARY

Installed executable:

/usr/sbin/asterisk

Check:

/usr/sbin/asterisk --version

Expected:

Asterisk 22.10.1
9. PJSIP SUPPORT

The project uses PJSIP.

Important modules include:

res_pjsip.so
res_pjsip_authenticator_digest.so
res_pjsip_endpoint_identifier_anonymous.so
res_pjsip_endpoint_identifier_ip.so
res_pjsip_endpoint_identifier_user.so
res_pjsip_pubsub.so
res_pjsip_session.so
chan_pjsip.so
10. SIP TRANSPORT

Baseline SIP transport:

[transport-udp]
type=transport
protocol=udp
bind=0.0.0.0:5060

Default:

UDP 5060
11. PJSIP CONFIGURATION

Main configuration:

/etc/asterisk/pjsip.conf

Baseline:

[transport-udp]
type=transport
protocol=udp
bind=0.0.0.0:5060

The installer can ask for a different bind address and UDP port.

12. EXTENSIONS CONFIGURATION

Main dialplan:

/etc/asterisk/extensions.conf

The baseline provides:

600

for the Echo test.

13. ECHO TEST

Baseline:

[default]
exten => 600,1,Answer()
 same => n,Echo()
 same => n,Hangup()

Calling extension 600 should answer and return the caller's audio.

14. MODULE LOADING

The project uses explicit module loading.

Main file:

/etc/asterisk/modules.conf

Required components are loaded explicitly.

Known unused modules are explicitly disabled where required.

15. CODECS

Baseline codecs:

codec_alaw.so
codec_ulaw.so
codec_g722.so
16. RTP

Baseline RTP module:

res_rtp_asterisk.so

RTP is required for SIP media.

17. ASTERISK DIRECTORY LAYOUT

Main directories:

/etc/asterisk
/usr/lib/asterisk/modules
/var/lib/asterisk
/var/run/asterisk
/var/log/asterisk
/usr/sbin
18. ASTERISK.CONF

Baseline:

[directories]
astetcdir => /etc/asterisk
astmoddir => /usr/lib/asterisk/modules
astvarlibdir => /var/lib/asterisk
astdbdir => /var/lib/asterisk
astrundir => /var/run/asterisk
astlogdir => /var/log/asterisk
astsbindir => /usr/sbin

[options]
19. LOGGER CONFIGURATION

Main file:

/etc/asterisk/logger.conf

Baseline:

[general]

[logfiles]
console => notice,warning,error
messages => notice,warning,error
20. SYSTEMD SERVICE

Service file:

/etc/systemd/system/asterisk.service

Asterisk is started in foreground mode:

/usr/sbin/asterisk -f
21. SYSTEMD SERVICE TYPE

The service uses:

Type=simple

This lets systemd directly manage the Asterisk process.

22. SYSTEMD ENABLEMENT

Enable at boot:

systemctl enable asterisk

Verify:

systemctl is-enabled asterisk

Expected:

enabled
23. ASTERISK SERVICE STATUS

Check:

systemctl status asterisk

Expected:

active (running)
24. SELINUX

The baseline keeps:

SELinux Enforcing

The project does not require disabling SELinux.

25. SELINUX LOCAL POLICY

Repository file:

selinux/asterisk-local-net.te

Policy:

module asterisk_local_net 1.0;

require {
    type asterisk_t;
    type sysctl_net_t;
    class dir search;
}

allow asterisk_t sysctl_net_t:dir search;

This permits the required network sysctl directory search.

26. SELINUX POLICY BUILD

Compile:

checkmodule -M -m -o asterisk-local-net.mod selinux/asterisk-local-net.te

Package:

semodule_package -o asterisk-local-net.pp -m asterisk-local-net.mod

Install:

semodule -i asterisk-local-net.pp
27. SELINUX VERIFICATION

Verify:

sesearch -A -s asterisk_t -t sysctl_net_t -c dir -p search

Check AVC messages:

ausearch -m AVC -ts recent

28. STASIS PATCH

Asterisk 22.10.1 requires the project Stasis taskpool source change.

Original:

static struct aco_type *taskpool_options[] = ACO_TYPES(&threadpool_option, &taskpool_option);

Project baseline:

static struct aco_type *taskpool_options[] = ACO_TYPES(&taskpool_option);

This resolves the configuration problem:

Could not find option 'minimum_size' with type 'threadpool' in module 'stasis'
29. STASIS PATCH FILE

Patch:

patches/asterisk-22.10.1-stasis-taskpool.patch

The installer applies this patch before compiling Asterisk.

The patch is specific to Asterisk 22.10.1.

30. STASIS.CONF

Configuration:

/etc/asterisk/stasis.conf

The baseline file may intentionally be empty.

Purpose:

Suppress missing configuration messages
31. OFFICIAL SAMPLE CONFIGURATIONS

Required sample configuration files are retained.

Examples:

acl.conf
ccss.conf
cdr.conf
cel.conf
features.conf
indications.conf
manager.conf
pjproject.conf
udptl.conf

Do not remove these files without validation.

32. REPOSITORY CONFIGURATION FILES

Configuration templates:

configs/asterisk/

Current files:

acl.conf
asterisk.conf
ccss.conf
cdr.conf
cel.conf
extensions.conf
features.conf
indications.conf
logger.conf
manager.conf
modules.conf
pjproject.conf
pjsip.conf
stasis.conf
udptl.conf
33. CONFIGURATION SOURCE OF TRUTH

Repository configuration is copied into:

/etc/asterisk

The Git repository defines the intended deployment baseline.

Manual server changes should be reviewed before becoming part of the official repository.

34. INSTALLER

Primary installer:

./install.sh

The installer is designed to complete the installation automatically after the administrator provides the required answers.

35. INTERACTIVE INSTALLATION

The administrator runs only:

./install.sh

The installer asks a small number of questions.

Example:

========================================
 Asterisk RHEL Deployment
========================================

RHEL detected: 9

Asterisk version [22.10.1]:
PJSIP bind address [0.0.0.0]:
PJSIP UDP port [5060]:

Install SELinux policy? [Y/n]:
Install systemd service? [Y/n]:
Start Asterisk after installation? [Y/n]:

Proceed with installation? [Y/n]:

Press:

ENTER

to accept the default.

The installer performs the remaining installation automatically.

36. INSTALLER AUTOMATIC STEPS

The installer performs:

1. Check root privileges
2. Detect RHEL version
3. Validate operating system
4. Ask required questions
5. Validate repositories
6. Install prerequisites
7. Download Asterisk source
8. Verify checksum
9. Install build prerequisites
10. Apply Stasis patch
11. Configure Asterisk
12. Compile Asterisk
13. Install Asterisk
14. Install configuration files
15. Configure PJSIP
16. Install SELinux policy
17. Install systemd service
18. Reload systemd
19. Enable Asterisk
20. Start Asterisk if selected
21. Run validation

37. DEFAULT INSTALLATION

For default values:

./install.sh --defaults

Defaults:

Asterisk version : 22.10.1
PJSIP bind      : 0.0.0.0
PJSIP UDP port  : 5060
SELinux policy  : yes
systemd service : yes
Start Asterisk  : yes
38. VERIFICATION SCRIPT

Run:

./verify.sh

The verification script should validate:

Operating system
Asterisk version
Asterisk binary
systemd
Asterisk service
PJSIP
SIP transport
SIP port
Loaded modules
Configuration
SELinux
Startup errors
39. ASTERISK CLI VALIDATION

Enter CLI:

asterisk -rvvv

Version:

core show version

PJSIP transports:

pjsip show transports

Modules:

module show
40. SIP LISTENING PORT

Check:

ss -lunp | grep ':5060'

Expected baseline:

0.0.0.0:5060
41. PJSIP TRANSPORT VALIDATION

Run:

asterisk -rx 'pjsip show transports'

The baseline should contain:

transport-udp
42. DIALPLAN VALIDATION

Run:

asterisk -rx 'dialplan show default'

The 600 extension should exist.

43. ECHO CALL TEST

Register a SIP client.

Call:

600

Expected:

Call answered
Echo application
Audio returned
Hangup
44. LOG VALIDATION

Show logs:

journalctl -u asterisk -b

Search:

journalctl -u asterisk -b | grep -iE 'ERROR|WARNING|failed|Asterisk Ready'

Expected clean startup:

Asterisk Ready.
45. REBOOT VALIDATION

Reboot:

reboot

After reboot:

systemctl status asterisk

Then:

journalctl -u asterisk -b | grep -iE 'ERROR|WARNING|failed|Asterisk Ready'

Asterisk should automatically start and become ready.

46. FIREWALL CONSIDERATIONS

SIP baseline:

UDP 5060

RTP ports depend on final RTP configuration.

Check firewall:

firewall-cmd --list-all

The final network design must allow the required SIP and RTP traffic.


47. NETWORK VALIDATION

Show addresses:

ip addr

Show routes:

ip route

Show listening sockets:

ss -lntup

Test gateway:

ping <gateway>
48. GIT REPOSITORY

Repository:

https://github.com/Omkar7039/asterisk-rhel-deployment.git

The repository is private.

GitHub should contain the complete deployment project.

49. GIT WORKFLOW

Recommended:

Modify
  |
  v
git status
  |
  v
git diff
  |
  v
git add
  |
  v
git commit
  |
  v
git push
50. VERSION FILE

Project version file:

VERSION

Example:

1.0.0

Future Git tags:

v1.0.0
v1.1.0
v2.0.0

A release should only be created after complete testing.

51. RELEASE VALIDATION

Before release, test:

Fresh RHEL 9 installation
Fresh RHEL 8 installation
GitHub clone
Interactive installer
Default installer
Verification script
Reboot
PJSIP
Echo call
SELinux
Systemd

Do not tag a release until the target environments are validated.

52. GITHUB CLONE WORKFLOW

Fresh server:

git clone https://github.com/Omkar7039/asterisk-rhel-deployment.git

Enter directory:

cd asterisk-rhel-deployment

Run installer:

./install.sh

Verify:

./verify.sh

The GitHub repository is the complete deployment source.

53. REPOSITORY STRUCTURE

Expected project structure:

asterisk-rhel-deployment/
├── README.md
├── VERSION
├── .gitignore
├── install.sh
├── verify.sh
├── build.sh
├── cleanup.sh
├── configs/
│   └── asterisk/
├── patches/
│   └── asterisk-22.10.1-stasis-taskpool.patch
├── selinux/
│   └── asterisk-local-net.te
└── systemd/
    └── asterisk.service
54. FUTURE DEVELOPMENT

Future improvements may include:

RHEL 8 automation
RHEL 9 automation
Installation profiles
Custom SIP templates
Custom dialplans
Additional endpoint templates
Firewall automation
RTP configuration
Upgrade scripts
Rollback support
Expanded verification
Release automation
GitHub CI testing
55. ADMINISTRATION GUIDELINES

Always review the repository state before changing production configuration.

Check:

cd /opt/asterisk-rhel-deployment
git status

Review differences:

git diff

Keep production configuration aligned with the tested repository baseline.

Do not manually delete Asterisk configuration files that are required by loaded modules.

56. COMPLETE INSTALLATION COMMANDS
56.1 Clone GitHub repository
git clone https://github.com/Omkar7039/asterisk-rhel-deployment.git
56.2 Enter project
cd asterisk-rhel-deployment
56.3 Interactive installation
./install.sh

The installer asks the administrator only the required questions.

Press ENTER to accept defaults.

56.4 Default installation
./install.sh --defaults
56.5 Verification
./verify.sh
56.6 Check version
asterisk --version
56.7 Check service
systemctl status asterisk
56.8 Start
systemctl start asterisk
56.9 Stop
systemctl stop asterisk
56.10 Restart
systemctl restart asterisk
56.11 Enable at boot
systemctl enable asterisk
56.12 Check enabled state
systemctl is-enabled asterisk
56.13 Check active state
systemctl is-active asterisk
56.14 Asterisk CLI
asterisk -rvvv
56.15 Show version
core show version
56.16 Show PJSIP transports
pjsip show transports
56.17 Show endpoints
pjsip show endpoints
56.18 Show registrations
pjsip show registrations
56.19 Show dialplan
dialplan show default
56.20 Show modules
module show
56.21 Check SIP port
ss -lunp | grep ':5060'
56.22 Check Asterisk process
ps -ef | grep '[a]sterisk'
56.23 Check SELinux
getenforce
56.24 Check SELinux policy
sesearch -A -s asterisk_t -t sysctl_net_t -c dir -p search
56.25 Check AVC
ausearch -m AVC -ts recent
56.26 Check logs
journalctl -u asterisk -b
56.27 Follow logs
journalctl -u asterisk -f
56.28 Search startup errors
journalctl -u asterisk -b | grep -iE 'ERROR|WARNING|failed|Asterisk Ready'
56.29 Check network
ip addr
56.30 Check routes
ip route
56.31 Check sockets
ss -lntup
56.32 Check firewall
firewall-cmd --list-all
56.33 Check Asterisk configuration
ls -lah /etc/asterisk
56.34 Check modules directory
ls -lah /usr/lib/asterisk/modules
56.35 Check Asterisk directories
ls -ld /var/lib/asterisk
ls -ld /var/log/asterisk
ls -ld /var/spool/asterisk
ls -ld /var/run/asterisk
56.36 Show systemd service
systemctl cat asterisk
56.37 Reload systemd
systemctl daemon-reload
56.38 Check core settings
asterisk -rx 'core show settings'
56.39 Check transports
asterisk -rx 'pjsip show transports'
56.40 Check dialplan
asterisk -rx 'dialplan show default'
56.41 Echo test

Call:

600
56.42 Reboot
reboot
56.43 Check after reboot
systemctl status asterisk
56.44 Check after reboot logs
journalctl -u asterisk -b | grep -iE 'ERROR|WARNING|failed|Asterisk Ready'
56.45 Git status
cd /opt/asterisk-rhel-deployment
git status
56.46 Git diff
git diff
56.47 Add changes
git add .
56.48 Commit
git commit -m "Update Asterisk deployment"
56.49 Push
git push
56.50 Check remote
git remote -v
56.51 Show commits
git log --oneline --decorate -10
56.52 Enter source directory
cd /usr/src/asterisk-22.10.1
56.53 Configure source
./configure
56.54 Build
make -j"$(nproc)"
56.55 Install
make install
56.56 Final verification
cd /opt/asterisk-rhel-deployment
./verify.sh

Final expected baseline:

Asterisk 22.10.1
PJSIP transport available
UDP 5060 listening
systemd active
SELinux Enforcing
Echo extension 600 available
Asterisk Ready.
END

Recommended fresh-server workflow:

git clone https://github.com/Omkar7039/asterisk-rhel-deployment.git
cd asterisk-rhel-deployment
./install.sh
./verify.sh

For default installation:

./install.sh --defaults

The installer asks the administrator only the required interactive questions and performs the remaining installation automatically.
