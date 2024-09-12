FROM ubuntu:noble

# Bootstrap

ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && \
    apt install -y --no-install-recommends \
      curl ca-certificates jq

WORKDIR /tmp/build

# Copy required scripts
ENV HELPER_SCRIPTS=/tmp/build/scripts/helpers
COPY --chmod=700 build/download.sh /tmp/build/
COPY --chmod=700 build/download-dir.sh /tmp/build/

# Download resources
RUN --mount=type=secret,id=GITHUB_TOKEN ./download-dir.sh scripts/helpers
RUN --mount=type=secret,id=GITHUB_TOKEN ./download-dir.sh scripts/build
RUN --mount=type=secret,id=GITHUB_TOKEN ./download-dir.sh scripts/tests
RUN --mount=type=secret,id=GITHUB_TOKEN ./download-dir.sh toolsets

# Copy required scripts
COPY --chmod=700 build/run.sh /tmp/build/

# Move specific path for tests due to hard-coded paths
RUN mkdir -p /imagegeneration/tests && \
    mv "scripts/tests" "/imagegeneration/tests"

# Configuration for the assumptions scripts make about APT
RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

# Fake out commands that won't work in a container
COPY --chmod=700 scripts/systemctl-fake.sh /usr/sbin/systemctl

# Start of scripts to be run

RUN ./run.sh scripts/build/configure-apt-mock.sh

RUN apt install -y --no-install-recommends lsb-release wget
RUN ./run.sh scripts/build/install-ms-repos.sh && \
    mkdir -p /etc/cloud/templates && \
   ./run.sh scripts/build/configure-apt-sources.sh && \
   ./run.sh scripts/build/configure-apt.sh

RUN ./run.sh scripts/build/configure-limits.sh

ARG IMAGEDATA_FILE=imagegeneration/imagedata.json
ARG IMAGE_VERSION=0.0.0
RUN mkdir -p $(dirname $IMAGEDATA_FILE) && \
    ./run.sh scripts/build/configure-image-data.sh

ARG IMAGE_OS="ubuntu24"

RUN apt install sudo && \
    echo "ResourceDisk.Format=n" > /etc/waagent.conf && \
    echo "ResourceDisk.EnableSwap=n" >> /etc/waagent.conf && \
    echo "ResourceDisk.SwapSizeMB=0" >> /etc/waagent.conf && \
    sed -i 's/\/etc\/hosts/\/tmp\/hosts/g' scripts/build/configure-environment.sh && \
    touch /tmp/hosts && \
    echo "ENABLED=0" >/etc/default/motd-news && \
    ./scripts/build/configure-environment.sh

ENV INSTALLER_SCRIPT_FOLDER=/tmp/build/toolsets
RUN mv toolsets/toolset-2404.json toolsets/toolset.json && \
    ./run.sh scripts/build/install-apt-vital.sh

RUN ./run.sh scripts/build/install-powershell.sh

RUN pwsh -f scripts/build/Install-PowerShellModules.ps1
RUN pwsh -f scripts/build/Install-PowerShellAzModules.ps1

RUN ./run.sh scripts/build/install-actions-cache.sh
RUN ./run.sh scripts/build/install-runner-package.sh
RUN ./run.sh scripts/build/install-apt-common.sh
