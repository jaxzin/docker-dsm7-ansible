# Minimal Docker-in-Docker base for DSM 7.2 parity testing
# Step 1: start from official Docker dind image
FROM docker:28.3.2-dind
#FROM docker:dind

## Step 2: add Python3 and pip (prerequisite for later Ansible/uv installs)
RUN apk add --no-cache python3 py3-pip \
    && ln -sf /usr/bin/python3 /usr/bin/python \
    && pip install docker ansible uv --break-system-packages

# Step 3: Timezone configuration to match DSM 7.2.2
# Install tzdata and set America/New_York timezone
RUN apk add --no-cache tzdata \
    && cp /usr/share/zoneinfo/America/New_York /etc/localtime \
    && echo "America/New_York" > /etc/timezone

# Step 4: Stub Python 2 interpreter for fingerprint compatibility
# Create a dummy python2.7 that reports the DSM-matching version
RUN printf '#!/bin/sh' > /usr/bin/python2.7 && \
    printf 'echo "Python 2.7.18"' >> /usr/bin/python2.7 && \
    chmod +x /usr/bin/python2.7 && \
    ln -sf /usr/bin/python2.7 /usr/bin/python2

# Step 5: Install DSM toolset packages
# Include key utilities to mirror Synology's system tools
RUN apk add --no-cache \
    busybox \
    rsyslog \
    cgroup-tools \
    parted \
    file \
    util-linux \
    iproute2 \
    open-iscsi \
    bash

# Step 6: Install storage & RAID packages to match DSM
RUN apk add --no-cache \
    btrfs-progs \
    lvm2 \
    mdadm \
    iptables

# Step 7: Stub /etc/VERSION with full DSM metadata
RUN mkdir -p /etc.defaults && \
    echo 'majorversion="7"'          > /etc.defaults/VERSION && \
    echo 'minorversion="2"'          >> /etc.defaults/VERSION && \
    echo 'major="7"'                 >> /etc.defaults/VERSION && \
    echo 'minor="2"'                 >> /etc.defaults/VERSION && \
    echo 'micro="2"'                 >> /etc.defaults/VERSION && \
    echo 'buildphase="GM"'           >> /etc.defaults/VERSION && \
    echo 'buildnumber="72806"'       >> /etc.defaults/VERSION && \
    echo 'smallfixnumber="3"'        >> /etc.defaults/VERSION && \
    echo 'nano="3"'                  >> /etc.defaults/VERSION && \
    echo 'base="72806"'              >> /etc.defaults/VERSION && \
    echo 'productversion="7.2.2"'    >> /etc.defaults/VERSION && \
    echo 'os_name="DSM"'             >> /etc.defaults/VERSION && \
    echo 'builddate="2025/01/20"'    >> /etc.defaults/VERSION && \
    echo 'buildtime="14:11:21"'      >> /etc.defaults/VERSION && \
    ln -sf /etc.defaults/VERSION /etc/VERSION

# Step 8: Stub Synology service & package tooling
# Provide no-op synoservice, synopkg, and synosystemctl scripts
RUN mkdir -p /usr/syno/bin && \
    for cmd in synoservice synopkg synosystemctl; do \
      echo -e '#!/bin/sh\nexit 0' > /usr/syno/bin/$cmd && \
      chmod +x /usr/syno/bin/$cmd; \
    done && \
    ln -sf /usr/syno/bin/synoservice /usr/bin/synoservice && \
    ln -sf /usr/syno/bin/synopkg /usr/bin/synopkg && \
    ln -sf /usr/syno/bin/synosystemctl /usr/bin/synosystemctl

# Step 9: Stub /etc/mtab for filesystem parity
# Simulate rootfs on ext4 as DSM does
RUN rm -f /etc/mtab && \
    echo '/dev/md2 / ext4 ro,relatime,data=ordered 0 1' > /etc/mtab

# Step 10: Replace /bin/sh with bash
# DSM uses bash as the default shell; ensure /bin/sh points to bash
RUN rm -f /bin/sh && \
    ln -sf /bin/bash /bin/sh

## Step 11: Explicitly set the Docker-in-Docker entrypoint
## Restore the DinD entrypoint so dockerd can launch correctly
#ENTRYPOINT ["dockerd-entrypoint.sh"]
#CMD ["--storage-driver=vfs"]
SHELL ["/bin/sh", "-c"]