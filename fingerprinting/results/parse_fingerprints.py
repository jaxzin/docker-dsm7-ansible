#!/usr/bin/env python3
import re

# Column widths including one-space left + right margins:
# [Feature col, Synology, Debian10, Debian11, Debian12, Ubuntu20.04]
COL_WIDTHS = [30, 158, 29, 29, 28, 29]

# Mapping of display names to log filenames
filenames = {
    "Synology DSM 7.2": "fingerprints/dsm7-fingerprint.log",
    "Debian 10 (Buster)": "fingerprints/debian10-fingerprint.log",
    "Debian 11 (Bullseye)": "fingerprint/debian11-fingerprint.log",
    "Debian 12 (Bookworm)": "fingerprints/debian12-fingerprint.log",
    "Ubuntu 20.04 (Focal)": "fingerprints/ubuntu2004-fingerprint.log",
}

def pad_cell(text, width):
    inner_width = width - 2
    text = text.replace('\n', ' ')
    if len(text) > inner_width:
        text = text[:inner_width-3] + '...'
    return ' ' + text.ljust(inner_width) + ' '

def parse_file(path):
    with open(path) as f:
        lines = [line.rstrip() for line in f]
    sections = {}
    current = None
    for line in lines:
        m = re.match(r"^=== (.+?) ===", line)
        if m:
            current = m.group(1)
            sections[current] = []
        elif current:
            sections[current].append(line)
    d = {}
    # OS Identification
    ossec = sections.get("OS Identification", [])
    for l in ossec:
        if l.startswith('majorversion'):
            d['os_name'] = 'Synology DSM'
        if l.startswith('ID='):
            d['os_id'] = l.split('=',1)[1].strip().strip('"')
        if l.startswith('VERSION_ID=') or l.startswith('productversion'):
            d['version_id'] = l.split('=',1)[1].strip().strip('"')
        if l.startswith('etc_issue='):
            d['issue'] = l.split('=',1)[1]
        if l.startswith('NAME=') and 'os_name' not in d:
            d['os_name'] = l.split('=',1)[1].strip().strip('"')
    d.setdefault('os_name','–')
    d.setdefault('os_id','–')
    d.setdefault('version_id','–')
    d.setdefault('issue','–')
    # Kernel & Compiler
    ksec = sections.get("Kernel & Compiler", [])
    if ksec:
        parts = ksec[0].split()
        d['kernel'] = parts[2] if len(parts)>=3 else '–'
        for l in ksec:
            m = re.search(r"gcc(?:\s*\([^\)]*\))?\s*(?:version\s*)?([0-9]+(?:\.[0-9]+)+)", l)
            if m:
                d['compiler'] = m.group(1)
                break
    d.setdefault('kernel','–')
    d.setdefault('compiler','–')
    # glibc
    gl = sections.get("glibc Version", [])
    d['glibc'] = gl[0].split(':',1)[1].strip() if gl and ':' in gl[0] else '–'
    # Init & systemd
    isec = sections.get("Init (PID 1) & systemd", [])
    d['init'] = 'systemd' if any('systemd' in l for l in isec) else '–'
    for l in isec:
        m = re.match(r"systemd (\d+)", l)
        if m:
            d['systemd'] = m.group(1)
            break
    d.setdefault('systemd','–')
    # Cgroup
    csec = sections.get("Cgroup Hierarchy", [])
    d['cgroup'] = csec[0].split(':',1)[1].strip() if csec and ':' in csec[0] else '–'
    # Python versions
    psec = sections.get("Python Versions", [])
    for l in psec:
        if l.startswith('python3:'):
            d['python3'] = l.split(':',1)[1].strip().replace('Python ','')
        if l.startswith('python2:'):
            d['python2'] = l.split(':',1)[1].strip().replace('Python ','')
    d.setdefault('python3','–')
    d.setdefault('python2','–')
    # Package managers
    pmsec = sections.get("Package Managers", [])
    for tool in ['synopkg','synosystemctl','apt','dpkg']:
        d[tool] = 'present' if any(l.startswith(tool+':') for l in pmsec) else '–'
    # Filesystem & tools
    fsec = sections.get("Filesystem & Tools", [])
    for l in fsec:
        if l.startswith('rootfs='): d['rootfs'] = l.split('=',1)[1]
        if 'btrfs-progs' in l: d['btrfs'] = l.split()[-1].replace('v', '')
        if 'mkfs.ext4' in l or 'mke2fs' in l: d['mkfs_ext4'] = 'mke2fs '+ l.split(maxsplit=1)[1]
        if l.startswith('  LVM version'): d['lvm'] = l.split(':',1)[1].strip()
        if l.lower().startswith('mdadm'): d['mdadm'] = l.split()[2].replace('v', '')
    for key in ['rootfs','btrfs','mkfs_ext4','lvm','mdadm']:
        d.setdefault(key,'not installed')
    # Shell & BusyBox
    sbsec = sections.get("Shell & BusyBox", [])
    d['shell'] = sbsec[0] if sbsec else '–'
    d['busybox'] = 'present' if any('BusyBox' in l for l in sbsec) else 'not installed'
    # Logging
    logsec = sections.get("Logging Stack", [])
    for l in logsec:
        if l.startswith('rsyslogd:'): d['rsyslogd'] = l.split(':',1)[1].strip()
        m = re.match(r"systemd (\d+)", l)
        if m: d['journalctl'] = m.group(1)
    d.setdefault('rsyslogd','not installed')
    d.setdefault('journalctl','not installed')
    # Security frameworks
    sfsec = sections.get("Security Frameworks", [])
    for l in sfsec:
        if l.startswith('AppArmor:'): d['apparmor'] = l.split(':',1)[1].strip()
        if l.startswith('SELinux'): d['selinux'] = l.split(':',1)[1].strip()
    d.setdefault('apparmor','not detected')
    d.setdefault('selinux','not detected')
    # Firewall
    fwsec = sections.get("Firewall Tools", [])
    for tool in ['iptables','nft']:
        d[tool] = next((l.split(':',1)[1].strip() for l in fwsec if l.startswith(tool+':')), 'not installed')
    # Locale & timezone
    ltsec = sections.get("Locale & Timezone", [])
    for l in ltsec:
        if l.startswith('LANG=') and l != 'LANG=': d['lang'] = l.split('=',1)[1].replace('_','\\_').strip()
        if l.startswith('timezone:'): d['timezone'] = l.split(':',1)[1].strip()
    d.setdefault('lang','(empty)')
    d.setdefault('timezone','–')
    # Loaded modules
    msec = sections.get("Loaded Kernel Modules (partial)", [])
    mods = [l.split()[0] for l in msec if l and not l.startswith('Module') and not l.startswith('Fingerprint')]
    d['modules'] = ', '.join(mods).replace('_','\\_') if mods else '–'
    return d

# Parse all logs
data = {name: parse_file(file) for name, file in filenames.items()}

# Build Markdown table with fixed column widths
headers = ["Feature"] + list(data.keys())

# Print header row
line = "|"
for idx, h in enumerate(headers):
    line += pad_cell(h, COL_WIDTHS[idx]) + "|"
print(line)

# Print separator row
sep = "|"
for w in COL_WIDTHS:
    sep += " " + "-" * (w-2) + " |"
print(sep)

# Define rows to output (one element per line)
rows = [
    ("OS Name",         "os_name"),
    ("OS ID",           "os_id"),
    ("Version ID",      "version_id"),
    ("/etc/issue",      "issue"),
    ("Kernel version",  "kernel"),
    ("Compiler (GCC)",  "compiler"),
    ("glibc version",   "glibc"),
    ("Init system",     "init"),
    ("systemd version", "systemd"),
    ("cgroup version",  "cgroup"),
    ("Python 3 version","python3"),
    ("Python 2 version","python2"),
    ("synopkg",         "synopkg"),
    ("synosystemctl",   "synosystemctl"),
    ("apt",             "apt"),
    ("dpkg",            "dpkg"),
    ("rootfs",          "rootfs"),
    ("btrfs-progs",     "btrfs"),
    ("mkfs.ext4",       "mkfs_ext4"),
    ("LVM version",     "lvm"),
    ("mdadm version",   "mdadm"),
    ("Default shell",           "shell"),
    ("BusyBox",         "busybox"),
    ("rsyslogd",        "rsyslogd"),
    ("journalctl",      "journalctl"),
    ("AppArmor",        "apparmor"),
    ("SELinux",         "selinux"),
    ("iptables",        "iptables"),
    ("nftables",        "nft"),
    ("LANG",            "lang"),
    ("Timezone",        "timezone"),
    ("Loaded modules (partial)",         "modules"),
]

for feature, key in rows:
    line = "|"
    # bold the feature value
    line += pad_cell(f"**{feature}**", COL_WIDTHS[0]) + "|"
    for idx, name in enumerate(data.keys(), start=1):
        line += pad_cell(data[name].get(key, "-"), COL_WIDTHS[idx]) + "|"
    print(line)
