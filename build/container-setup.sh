#!/usr/bin/env bash
set -euo pipefail

# Configuration for the assumptions scripts make about APT
echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

# Fake out commands that won't work in a container
echo 'echo "Skipping: $0 $*"' > /usr/sbin/systemctl && \
    chmod +x /usr/sbin/systemctl && \
    echo 'echo "Skipping: $0 $*"' > /usr/sbin/journalctl && \
    chmod +x /usr/sbin/journalctl

# Create expected directories and files
mkdir -p /etc/cloud/templates && \
    mkdir /imagegeneration/post-generation && \
    mkdir /etc/needrestart && touch /etc/needrestart/needrestart.conf

# Fudge file content that's not relevant in a container
echo "ResourceDisk.Format=n" > /etc/waagent.conf && \
    echo "ResourceDisk.EnableSwap=n" >> /etc/waagent.conf && \
    echo "ResourceDisk.SwapSizeMB=0" >> /etc/waagent.conf && \
    sed -i 's/\/etc\/hosts/\/tmp\/hosts/g' scripts/build/configure-environment.sh && \
    touch /tmp/hosts && \
    echo "ENABLED=0" >/etc/default/motd-news

# Need to avoid conflict with netcat-openbsd on noble
# It's not clear how GitHub's install script handles this.
sed -i 's/netcat/netcat-openbsd/g' toolsets/toolset.json && \
    sed -i 's/"net-tools"/"netcat-openbsd" { \$toolName = "netcat"; break }\n"net-tools"/g' $IMAGE_FOLDER/tests/Apt.Tests.ps1

# We cannot create a podman network so we need to disable these specific tests
sed -i '/"podman CNI plugins"/,/}/ s/.*//g' $IMAGE_FOLDER/tests/Tools.Tests.ps1

# Setup Bazel install needs
useradd -m -s /bin/bash -u 1001 bazel && \
    echo 'echo "1.0"' >/usr/local/bin/version && \
    chmod +x /usr/local/bin/version

# Installed assumed tools
apt install -y --no-install-recommends \
    lsb-release wget sudo
