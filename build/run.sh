#!/usr/bin/env bash
set -eo pipefail

if [ -z "$1" ]; then
  echo "Usage: $0 <script>"
  exit 1
fi

base_dir=$(dirname "$0")
script=$1

echo "======================------------------"
cat "$base_dir/$script"
echo "----------------------=================="

set -x
# shellcheck disable=SC1090
source "$base_dir/$script"
