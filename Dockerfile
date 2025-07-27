# Use Ubuntu 20.04 LTS (Focal) as base
FROM geerlingguy/docker-ubuntu2004-ansible

###############################################################################
# Install and pin DSM-matching versions (or closest available) and hold them:
RUN apt-get update && \
    apt install software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      python2.7=2.7.18-1~20.04.7 \
      python3.10=3.10.18-1+focal1 \
      btrfs-progs=5.4.1-2 \
      lvm2=2.03.07-1ubuntu1 \
      mdadm=4.1-5ubuntu1.2 \
      iptables=1.8.4-3ubuntu2.1 \
      libip4tc2 \
      libip6tc2 \
      libxtables12 && \
    apt-mark hold python2.7 btrfs-progs lvm2 mdadm iptables

###############################################################################
# Additional packages for DSM parity
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      python3-pip locales tzdata busybox rsyslog cgroup-tools \
      parted file util-linux iproute2 open-iscsi && \
    rm -f /usr/bin/apt  # hide apt so fingerprint script shows only dpkg

###############################################################################
# Interpreter and firewall adjustments:
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 10 && \
    update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1 && \
    update-alternatives --set iptables /usr/sbin/iptables-legacy && \
    rm -f /bin/sh && ln -s /usr/bin/bash /bin/sh

###############################################################################
# Locale & Timezone configuration to match Synology DSM 7.2.2
RUN locale-gen en_US.utf8 && \
    update-locale LANG=en_US.utf8 && \
    ln -snf /usr/share/zoneinfo/America/New_York /etc/localtime && \
    echo "America/New_York" > /etc/timezone

###############################################################################
# Stub Synology VERSION file with full DSM metadata, remove Ubuntu's os-release
RUN mkdir -p /etc.defaults && \
    printf 'majorversion="7"\nminorversion="2"\nmajor="7"\nminor="2"\nmicro="2"\nbuildphase="GM"\nbuildnumber="72806"\nsmallfixnumber="3"\nnano="3"\nbase="72806"\nproductversion="7.2.2"\nos_name="DSM"\nbuilddate="2025/01/20"\nbuildtime="14:11:21"\n' > /etc.defaults/VERSION && \
    ln -sf /etc.defaults/VERSION /etc/VERSION

###############################################################################
# Stub Synology service & package tooling
RUN mkdir -p /usr/syno/bin && \
    for cmd in synoservice synopkg synosystemctl; do \
      printf '#!/bin/bash\nexit 0\n' > /usr/syno/bin/$cmd && chmod +x /usr/syno/bin/$cmd; \
    done && \
    ln -sf /usr/syno/bin/synoservice /usr/bin/synoservice && \
    ln -sf /usr/syno/bin/synopkg /usr/bin/synopkg && \
    ln -sf /usr/syno/bin/synosystemctl /usr/bin/synosystemctl

###############################################################################
# Python2 alias for DSM fingerprint script
RUN ln -sf /usr/bin/python2.7 /usr/bin/python2

###############################################################################
# Stub rootfs type via /etc/mtab (for Filesystem & Tools parity)
RUN rm -f /etc/mtab && \
    echo '/dev/md2 / ext4 ro,relatime,data=ordered 0 1' > /etc/mtab

###############################################################################
# (Optional) Mount tmpfs at runtime for cgroup hierarchy
RUN printf '#!/bin/bash\nmount -t tmpfs tmpfs /sys/fs/cgroup -o nosuid,nodev,noexec,mode=755\nexec "$@"\n' > /usr/local/bin/docker-entrypoint.sh && \
    chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/bin/bash"]
