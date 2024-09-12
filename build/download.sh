#!/usr/bin/env bash
set -eo pipefail

if [ -z "$1" ]; then
  echo "Usage: $0 <script>"
  exit 1
fi

base_url=https://github.com/actions/runner-images/blob/main/images/ubuntu
base_dir=$(dirname "$0")
script=$1

mkdir -p "$(dirname "$script")"
curl --silent --show-error --location --output "$base_dir/$script" \
  "$base_url/$script?raw=true"

chmod +x "$base_dir/$script"
