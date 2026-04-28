#!/usr/bin/env bash
set -euo pipefail

target_bin="${1:-$HOME/bin}"
profile_dir="${CLAUDE_PROFILES_DIR:-$HOME/.claude-profiles}"

mkdir -p "$target_bin" "$profile_dir"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
install -m 0755 "$script_dir/bin/cc-provider" "$target_bin/cc-provider"

ln -sf "$target_bin/cc-provider" "$target_bin/ccglm"
ln -sf "$target_bin/cc-provider" "$target_bin/ccminimax"
ln -sf "$target_bin/cc-provider" "$target_bin/cclocal"
ln -sf "$target_bin/cc-provider" "$target_bin/ccdeepseek"

if [[ ! -f "$profile_dir/providers.json" ]]; then
  cp "$script_dir/providers.example.json" "$profile_dir/providers.json"
fi

cat <<EOF
Installed Claude Code provider launchers to:
  $target_bin

Provider config:
  $profile_dir/providers.json

Add this to your shell profile if needed:
  export PATH="$target_bin:\$PATH"
EOF
