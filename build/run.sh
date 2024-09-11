#!/usr/bin/env bash
set -euo pipefail

if [ -z "$1" ]; then
  echo "Usage: $0 <script>"
  exit 1
fi

base_dir=$(dirname "$0")
script=$1

"$base_dir/download.sh" "$script"

echo "======================------------------"
cat "$base_dir/$script"
echo "----------------------=================="

"$base_dir/$script"
