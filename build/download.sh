#!/usr/bin/env bash
set -eo pipefail

if [ -z "$1" ]; then
  echo "Usage: $0 <script>"
  exit 1
fi

base_url="https://api.github.com/repos/actions/runner-images/contents/images/ubuntu"
base_dir=$(dirname "$0")
script=$1

mkdir -p "$(dirname "$script")"
curl \
  --silent --show-error --location \
  --header "Accept: application/vnd.github+json" \
  --header "Authorization: Bearer $(cat /run/secrets/GITHUB_TOKEN)" \
  --url "$base_url/$script" | \
  jq -r '.content' | \
  base64 --decode > "$base_dir/$script"

chmod +x "$base_dir/$script"
