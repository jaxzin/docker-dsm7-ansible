#!/bin/sh
#
# dsm-full-fingerprint.sh
# Gather detailed DSM environment info for downstream comparison.
# Does NOT exit on missing commands and handles glibc detection gracefully.
#

# Don’t abort on missing tools
# (we’ll check for each before running)

sec() {
  printf "\n=== %s ===\n" "$1"
}

# 1) OS Identification
sec "OS Identification"
if [ -f /etc/os-release ]; then
  awk -F= '/^NAME=|^VERSION_ID=|^ID=/{print $1"="$2}' /etc/os-release || :
elif [ -f /etc/VERSION ]; then
  # DSM’s own version file
  awk -F= '/^majorversion=|^minorversion=|^productversion=/{print}' /etc/VERSION || :
elif [ -f /etc.defaults/VERSION ]; then
  # fallback if /etc/VERSION isn’t present
  awk -F= '/^majorversion=|^minorversion=|^productversion=/{print}' /etc.defaults/VERSION || :
else
  echo "DSM version info: not found"
fi
[ -f /etc/issue ] && echo "etc_issue=$(head -1 /etc/issue)" || :

# 2) Kernel & Compiler
sec "Kernel & Compiler"
uname -a || echo "uname: not available"
cat /proc/version 2>/dev/null || echo "/proc/version: not available"

# 3) glibc Version
sec "glibc Version"
# 1) Preferred: getconf
if command -v getconf >/dev/null 2>&1; then
  ver=$(getconf GNU_LIBC_VERSION 2>/dev/null | awk '{print $2}')
  [ -n "$ver" ] && echo "glibc (getconf): $ver" || echo "glibc (getconf): empty"
# 2) Next: ldconfig listing
elif command -v ldconfig >/dev/null 2>&1; then
  libpath=$(ldconfig -p 2>/dev/null | awk '/libc\.so\.6/{print $NF; exit}')
  [ -n "$libpath" ] && echo "glibc (ldconfig): $(basename "$libpath")" \
    || echo "glibc (ldconfig): entry not found"
# 3) Finally: inspect the libc.so.6 symlink
elif [ -e /lib/libc.so.6 ] || [ -e /usr/lib/libc.so.6 ]; then
  for path in /lib/libc.so.6 /usr/lib/libc.so.6; do
    [ -e "$path" ] || continue
    target=$(readlink -f "$path")
    echo "glibc (link): $(basename "$target")"
    break
  done
else
  echo "glibc: unknown (no getconf, ldconfig, or libc.so.6)"
fi

# 4) Init (PID 1) & systemd
sec "Init (PID 1) & systemd"
ps -p 1 -o pid,ppid,comm,args || echo "ps: failed"
if command -v systemctl >/dev/null 2>&1; then
  systemctl --version | head -n1
else
  echo "systemctl: not found"
fi

# 5) Cgroup Version/Mode
sec "Cgroup Hierarchy"
if [ -f /sys/fs/cgroup/cgroup.controllers ]; then
  echo "cgroup: v2 unified"
else
  echo "cgroup: v1"
fi
mount | grep cgroup || :

# 6) Python Versions
sec "Python Versions"
for py in python python2 python3; do
  if command -v $py >/dev/null 2>&1; then
    printf "%s: " "$py"
    $py --version 2>&1 || :
  else
    echo "$py: not installed"
  fi
done

# 7) Package Managers
sec "Package Managers"
for pm in synopkg synoservice synosystemctl apt dpkg yum rpm zypper apk opkg; do
  if command -v $pm >/dev/null 2>&1; then
    # We only need to know it exists—no version required for Synology tools
    echo "$pm: present"
  fi
done

# 8) Filesystem & Tools
sec "Filesystem & Tools"
mount | grep ' / ' | awk '{print "rootfs="$5}' || :
if command -v btrfs >/dev/null 2>&1; then
  btrfs --version | head -n1 || :
fi
if command -v mkfs.ext4 >/dev/null 2>&1; then
  mkfs.ext4 -V 2>&1 | head -n1 || :
fi
if command -v lvm >/dev/null 2>&1; then
  lvm version | head -n3 || :
fi
if command -v mdadm >/dev/null 2>&1; then
  mdadm --version | head -n1 || :
fi

# 9) Shell & BusyBox
sec "Shell & BusyBox"
readlink -f /bin/sh || echo "/bin/sh link not found"
if command -v busybox >/dev/null 2>&1; then
  busybox | head -n1 || :
fi

# 10) Synology Service Tooling
sec "Synology Service Tooling"
for tool in synoservice synosystemctl synopkg; do
  if command -v $tool >/dev/null 2>&1; then
    # Presence confirms we can invoke Synology’s service APIs
    echo "$tool: present"
  fi
done

# 11) Logging Stack
sec "Logging Stack"
if command -v rsyslogd >/dev/null 2>&1; then
  rsyslogd --version | head -n1 || :
else
  echo "rsyslogd: not installed"
fi
if command -v journalctl >/dev/null 2>&1; then
  journalctl --version | head -n1 || :
fi

# 12) Security Frameworks
sec "Security Frameworks"
[ -d /sys/kernel/security/apparmor ] && echo "AppArmor: enabled" || echo "AppArmor: not detected"
if command -v selinuxenabled >/dev/null 2>&1; then
  echo "SELinux: $(selinuxenabled && echo enabled || echo disabled)"
fi

# 13) Firewall Tools
sec "Firewall Tools"
for fw in iptables nft; do
  if command -v $fw >/dev/null 2>&1; then
    printf "%s: " "$fw"
    $fw --version 2>&1 | head -n1 || :
  fi
done

# 14) Locale & Timezone
sec "Locale & Timezone"
locale | grep LANG= || :
echo "timezone: $(date +%Z)" || :

# 15) Loaded Kernel Modules (partial)
sec "Loaded Kernel Modules (partial)"
lsmod | head -n10 || :

echo ""
echo "Fingerprint complete."