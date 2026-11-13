#!/bin/sh
# Runs the production AccountState with synthetic HTTP, session storage and authorization.
set -eu
repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
check_dir=$(mktemp -d "${TMPDIR:-/tmp}/godieor-account-check.XXXXXX")
trap 'rm -rf "$check_dir"' EXIT HUP INT TERM
xcrun swiftc -module-cache-path "$check_dir/cache" -parse-as-library \
  "$repo_dir/ios/GODIEOR/PublicAPI.swift" \
  "$repo_dir/ios/GODIEOR/Account.swift" \
  "$repo_dir/tests/AccountFlowChecks.swift" -o "$check_dir/check"
"$check_dir/check"
