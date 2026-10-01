#!/bin/sh
set -eu

repo_dir="$(cd "$(dirname "$0")" && pwd)"
hs_dir="$HOME/.hammerspoon"
init="$hs_dir/init.lua"

mkdir -p "$hs_dir"
ln -sfn "$repo_dir" "$hs_dir/hs-llm-hotkeys"

if ! grep -qs 'require("hs-llm-hotkeys")' "$init"; then
  printf '\nrequire("hs-llm-hotkeys").start({})\n' >> "$init"
fi

echo "installed: $hs_dir/hs-llm-hotkeys -> $repo_dir"
