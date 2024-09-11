FROM ubuntu:noble

# Bootstrap

ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && \
    apt install -y --no-install-recommends \
      curl ca-certificates

COPY --chmod=700 build/ /tmp/build/
WORKDIR /tmp/build

# Setup

ENV HELPER_SCRIPTS=/tmp/build/scripts/helpers
RUN ./download.sh scripts/helpers/os.sh
RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes
COPY --chmod=700 scripts/systemctl-fake.sh /usr/sbin/systemctl

# Start of scripts to be run

RUN ./run.sh scripts/build/configure-apt-mock.sh

RUN apt install -y --no-install-recommends lsb-release wget
RUN \
   ./run.sh scripts/build/install-ms-repos.sh && \
    mkdir -p /etc/cloud/templates && \
   ./run.sh scripts/build/configure-apt-sources.sh && \
   ./run.sh scripts/build/configure-apt.sh

RUN ./run.sh scripts/build/configure-limits.sh

ARG IMAGEDATA_FILE=imagegeneration/imagedata.json
ARG IMAGE_VERSION=0.0.0
COPY --chmod=700 scripts/configure-image-data.sh ./
RUN mkdir -p $(dirname $IMAGEDATA_FILE) && \
    ./run.sh scripts/build/configure-image-data.sh

ARG IMAGE_OS="ubuntu24"
RUN ./download.sh scripts/helpers/etc-environment.sh && \
    apt install sudo && \
    echo "ResourceDisk.Format=n" > /etc/waagent.conf && \
    echo "ResourceDisk.EnableSwap=n" >> /etc/waagent.conf && \
    echo "ResourceDisk.SwapSizeMB=0" >> /etc/waagent.conf && \
    ./download.sh scripts/build/configure-environment.sh && \
    sed -i 's/\/etc\/hosts/\/tmp\/hosts/g' scripts/build/configure-environment.sh && \
    touch /tmp/hosts && \
    ./download.sh scripts/helpers/invoke-tests.sh && \
    echo "ENABLED=0" >/etc/default/motd-news && \
    ./scripts/build/configure-environment.sh

ENV INSTALLER_SCRIPT_FOLDER=/tmp/build/toolsets
RUN ./download.sh scripts/helpers/install.sh && \
    ./download.sh toolsets/toolset-2404.json && \
    mv toolsets/toolset-2404.json toolsets/toolset.json && \
    nl scripts/helpers/install.sh && \
    ./run.sh scripts/build/install-apt-vital.sh
