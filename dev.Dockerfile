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

ARG IMAGE_OS="ubuntu24"
ARG IMAGE_VERSION=0.0.0

# Setup directories. Must be in these specific directories due to hard-coded paths
ENV IMAGE_FOLDER=/imagegeneration
ARG BUILD_DIR=$IMAGE_FOLDER/build
ARG IMAGEDATA_FILE=$IMAGE_FOLDER/imagedata.json
ENV HELPER_SCRIPTS=$IMAGE_FOLDER/helpers
ENV HELPER_SCRIPT_FOLDER=$HELPER_SCRIPTS
ENV INSTALLER_SCRIPT_FOLDER=$BUILD_DIR/toolsets

WORKDIR $BUILD_DIR
RUN mkdir -p $(dirname $IMAGEDATA_FILE)

# Relocate required scripts
RUN mv $DOWNLOAD_DIR/scripts/tests $IMAGE_FOLDER/tests && \
    mv $DOWNLOAD_DIR/scripts/helpers $IMAGE_FOLDER/helpers && \
    mv $DOWNLOAD_DIR/scripts scripts && \
    mv $DOWNLOAD_DIR/toolsets toolsets && \
    cp toolsets/toolset-2404.json toolsets/toolset.json

COPY --chmod=700 build/run.sh ./
COPY --chmod=700 build/container-setup.sh ./
COPY --chmod=700 build/install-all.sh ./

# Configuration for the assumptions scripts make
RUN ./container-setup.sh

# Invoke GitHub install scripts

RUN ./run.sh scripts/build/configure-apt-mock.sh

RUN ./run.sh scripts/build/install-ms-repos.sh
RUN ./run.sh scripts/build/configure-apt-sources.sh
RUN ./run.sh scripts/build/configure-apt.sh

RUN ./run.sh scripts/build/configure-limits.sh

RUN ./run.sh scripts/build/configure-image-data.sh

RUN ./scripts/build/configure-environment.sh

RUN ./run.sh scripts/build/install-apt-vital.sh

RUN ./run.sh scripts/build/install-powershell.sh
RUN pwsh -f scripts/build/Install-PowerShellModules.ps1
RUN pwsh -f scripts/build/Install-PowerShellAzModules.ps1

RUN ./run.sh scripts/build/install-actions-cache.sh
RUN ./run.sh scripts/build/install-runner-package.sh

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

RUN ./run.sh scripts/build/install-container-tools.sh

RUN ./run.sh scripts/build/install-dotnetcore-sdk.sh
RUN ./run.sh scripts/build/install-microsoft-edge.sh
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

RUN # Requires system booted with systemd
RUN #./run.sh scripts/build/install-mysql.sh

RUN # Requires system booted with systemd
RUN #./run.sh scripts/build/install-nginx.sh

RUN ./run.sh scripts/build/install-nodejs.sh

RUN ./run.sh scripts/build/install-bazel.sh

RUN ./run.sh scripts/build/install-php.sh

RUN # Requires system booted with systemd
RUN #./run.sh scripts/build/install-postgresql.sh

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

RUN # A systemctl startup. Needs customisation
RUN #./run.sh scripts/build/install-docker.sh

RUN pwsh -f scripts/build/Install-Toolset.ps1

RUN # Weird path issues with yamllint and ansible
RUN #./run.sh scripts/build/install-pipx-packages.sh

RUN ./run.sh scripts/build/install-homebrew.sh

RUN # Needs systemctl
RUN #./run.sh scripts/build/configure-snap.sh

RUN ./run.sh scripts/build/cleanup.sh

RUN ./run.sh scripts/build/configure-system.sh
