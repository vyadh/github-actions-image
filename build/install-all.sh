#!/usr/bin/env bash
set -euo pipefail

scripts/build/configure-apt-mock.sh

scripts/build/install-ms-repos.sh
scripts/build/configure-apt-sources.sh
scripts/build/configure-apt.sh

scripts/build/configure-limits.sh

scripts/build/configure-image-data.sh

./scripts/build/configure-environment.sh

scripts/build/install-apt-vital.sh

scripts/build/install-powershell.sh
pwsh -f scripts/build/Install-PowerShellModules.ps1
pwsh -f scripts/build/Install-PowerShellAzModules.ps1

scripts/build/install-actions-cache.sh
scripts/build/install-runner-package.sh

scripts/build/install-apt-common.sh
scripts/build/install-azcopy.sh
scripts/build/install-azure-cli.sh
scripts/build/install-azure-devops-cli.sh
scripts/build/install-bicep.sh
scripts/build/install-apache.sh
scripts/build/install-aws-tools.sh
scripts/build/install-clang.sh
scripts/build/install-swift.sh
scripts/build/install-cmake.sh
scripts/build/install-codeql-bundle.sh

scripts/build/install-container-tools.sh

scripts/build/install-dotnetcore-sdk.sh
scripts/build/install-microsoft-edge.sh
scripts/build/install-gcc-compilers.sh
scripts/build/install-gfortran.sh
scripts/build/install-git.sh
scripts/build/install-git-lfs.sh
scripts/build/install-github-cli.sh
scripts/build/install-google-chrome.sh
scripts/build/install-haskell.sh
scripts/build/install-java-tools.sh
scripts/build/install-kubernetes-tools.sh
scripts/build/install-miniconda.sh
scripts/build/install-kotlin.sh

# Requires system booted with systemd
#scripts/build/install-mysql.sh

# Requires system booted with systemd
#scripts/build/install-nginx.sh

scripts/build/install-nodejs.sh

scripts/build/install-bazel.sh

scripts/build/install-php.sh

# Requires system booted with systemd
#scripts/build/install-postgresql.sh

scripts/build/install-pulumi.sh
scripts/build/install-ruby.sh
scripts/build/install-rust.sh
scripts/build/install-julia.sh
scripts/build/install-selenium.sh
scripts/build/install-packer.sh
scripts/build/install-vcpkg.sh
scripts/build/configure-dpkg.sh
scripts/build/install-yq.sh
scripts/build/install-android-sdk.sh
scripts/build/install-pypy.sh
scripts/build/install-python.sh
scripts/build/install-zstd.sh

# A systemctl startup. Needs customisation
#scripts/build/install-docker.sh

pwsh -f scripts/build/Install-Toolset.ps1

# Weird path issues with yamllint and ansible
#scripts/build/install-pipx-packages.sh

scripts/build/install-homebrew.sh

# Needs systemctl
#scripts/build/configure-snap.sh

scripts/build/cleanup.sh

scripts/build/configure-system.sh
