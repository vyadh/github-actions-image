FROM ubuntu:noble

# Bootstrap

ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && \
    apt install -y --no-install-recommends \
      curl ca-certificates jq

# Copy required scripts to a download folder (avoiding changes that would invalidate the cache)
ARG DOWNLOAD_DIR=/tmp/download
WORKDIR $DOWNLOAD_DIR
COPY --chmod=700 build/download.sh $DOWNLOAD_DIR/
COPY --chmod=700 build/download-dir.sh $DOWNLOAD_DIR/

# Download resources
RUN --mount=type=secret,id=GITHUB_TOKEN ./download-dir.sh scripts/build
RUN --mount=type=secret,id=GITHUB_TOKEN ./download-dir.sh scripts/helpers
RUN --mount=type=secret,id=GITHUB_TOKEN ./download-dir.sh scripts/tests
RUN --mount=type=secret,id=GITHUB_TOKEN ./download-dir.sh toolsets

# Setup directories. Must be in these specific directories due to hard-coded paths
ARG BASE_DIR=/imagegeneration
ARG BUILD_DIR=/imagegeneration/build
WORKDIR $BUILD_DIR
ENV HELPER_SCRIPTS=$BASE_DIR/helpers
ENV INSTALLER_SCRIPT_FOLDER=$BUILD_DIR/toolsets

# Relocate required scripts
RUN mv $DOWNLOAD_DIR/scripts/tests $BASE_DIR/tests
RUN mv $DOWNLOAD_DIR/scripts/helpers $BASE_DIR/helpers
RUN mv $DOWNLOAD_DIR/scripts scripts
RUN mv $DOWNLOAD_DIR/toolsets toolsets
RUN cp toolsets/toolset-2404.json toolsets/toolset.json

# Configuration for the assumptions scripts make about APT
RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

# Fake out commands that won't work in a container
COPY --chmod=700 scripts/systemctl-fake.sh /usr/sbin/systemctl

# Invoke GitHub install scripts

COPY --chmod=700 build/run.sh ./

RUN ./run.sh scripts/build/configure-apt-mock.sh

RUN apt install -y --no-install-recommends lsb-release wget
RUN ./run.sh scripts/build/install-ms-repos.sh && \
    mkdir -p /etc/cloud/templates && \
   ./run.sh scripts/build/configure-apt-sources.sh && \
   ./run.sh scripts/build/configure-apt.sh

RUN ./run.sh scripts/build/configure-limits.sh

ARG IMAGEDATA_FILE=$BASE_DIR/imagedata.json
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

RUN ./run.sh scripts/build/install-apt-vital.sh

RUN ./run.sh scripts/build/install-powershell.sh
RUN pwsh -f scripts/build/Install-PowerShellModules.ps1
RUN pwsh -f scripts/build/Install-PowerShellAzModules.ps1

RUN ./run.sh scripts/build/install-actions-cache.sh
RUN ./run.sh scripts/build/install-runner-package.sh

# Need to avoid conflict with netcat-openbsd on noble
# It's not clear how GitHub's install script handles this.
RUN sed -i 's/netcat/netcat-openbsd/g' toolsets/toolset.json && \
    sed -i 's/"net-tools"/"netcat-openbsd" { \$toolName = "netcat"; break }\n"net-tools"/g' $BASE_DIR/tests/Apt.Tests.ps1

RUN ./run.sh scripts/build/install-apt-common.sh
RUN ./run.sh scripts/build/install-azcopy.sh
RUN ./run.sh scripts/build/install-azure-cli.sh
RUN ./run.sh scripts/build/install-azure-devops-cli.sh
RUN ./run.sh scripts/build/install-bicep.sh
RUN ./run.sh scripts/build/install-apache.sh
RUN ./run.sh scripts/build/install-aws-tools.sh
RUN ./run.sh scripts/build/install-clang.sh
RUN ./run.sh scripts/build/install-swift.sh
RUN ./run.sh scripts/build/install-cmake.sh
RUN ./run.sh scripts/build/install-codeql-bundle.sh

# We cannot create a podman network so we need to disable these specific tests
RUN sed -i '/"podman CNI plugins"/,/}/ s/.*//g' $BASE_DIR/tests/Tools.Tests.ps1

RUN ./run.sh scripts/build/install-container-tools.sh
RUN ./run.sh scripts/build/install-dotnetcore-sdk.sh
RUN ./run.sh scripts/build/install-gcc-compilers.sh
RUN ./run.sh scripts/build/install-gfortran.sh
RUN ./run.sh scripts/build/install-git.sh
RUN ./run.sh scripts/build/install-git-lfs.sh
RUN ./run.sh scripts/build/install-github-cli.sh
RUN ./run.sh scripts/build/install-google-chrome.sh
RUN ./run.sh scripts/build/install-haskell.sh
RUN ./run.sh scripts/build/install-java-tools.sh
RUN ./run.sh scripts/build/install-kubernetes-tools.sh
RUN ./run.sh scripts/build/install-miniconda.sh
RUN ./run.sh scripts/build/install-kotlin.sh

# Requires system booted with systemd
#RUN ./run.sh scripts/build/install-mysql.sh

# Requires system booted with systemd
#RUN ./run.sh scripts/build/install-nginx.sh

RUN ./run.sh scripts/build/install-nodejs.sh

RUN useradd -m -s /bin/bash -u 1001 bazel && \
    echo 'echo "1.0"' >/usr/local/bin/version && \
    chmod +x /usr/local/bin/version
RUN ./run.sh scripts/build/install-bazel.sh

RUN ./run.sh scripts/build/install-php.sh

# Requires system booted with systemd
#RUN ./run.sh scripts/build/install-postgresql.sh

RUN ./run.sh scripts/build/install-pulumi.sh
RUN ./run.sh scripts/build/install-ruby.sh
RUN ./run.sh scripts/build/install-rust.sh
RUN ./run.sh scripts/build/install-julia.sh
RUN ./run.sh scripts/build/install-selenium.sh
RUN ./run.sh scripts/build/install-packer.sh
RUN ./run.sh scripts/build/install-vcpkg.sh
RUN ./run.sh scripts/build/configure-dpkg.sh
RUN ./run.sh scripts/build/install-yq.sh
RUN ./run.sh scripts/build/install-android-sdk.sh
RUN ./run.sh scripts/build/install-pypy.sh
RUN ./run.sh scripts/build/install-python.sh
RUN ./run.sh scripts/build/install-zstd.sh
