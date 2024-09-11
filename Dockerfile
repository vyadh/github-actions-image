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

# Start of scripts to be run

RUN ./run.sh scripts/build/configure-apt-mock.sh

RUN apt install -y --no-install-recommends lsb-release wget
RUN \
   ./run.sh "scripts/build/install-ms-repos.sh" && \
    mkdir -p /etc/cloud/templates && \
   ./run.sh "scripts/build/configure-apt-sources.sh" && \
   ./run.sh "scripts/build/configure-apt.sh" \
