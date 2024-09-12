#!/usr/bin/env bash
set -eo pipefail
set -x

if [ -z "$1" ]; then
  echo "Usage: $0 <dir>"
  exit 1
fi

base_url="https://api.github.com/repos/actions/runner-images/contents/images/ubuntu"
dir=$1

url="$base_url/$dir"
files=$(curl -s "$url" | jq -r '.[] | .name')

mkdir -p "$dir"

for file in $files; do
  path="$dir/$file"
  ./download.sh "$path"
done
