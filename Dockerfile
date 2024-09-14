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

# Configuration for the assumptions the GitHub scripts make
RUN ./container-setup.sh

# Invoke GitHub install scripts
RUN ./install-all.sh
