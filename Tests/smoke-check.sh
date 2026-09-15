#!/bin/bash
set -eu
cd "$(dirname "$0")/.."
check_build=$(mktemp -d "${TMPDIR:-/tmp}/clipbatcher-build.XXXXXX")
trap 'rm -rf "$check_build"' EXIT
swiftc -swift-version 5 -parse-as-library -module-cache-path "$check_build/module-cache" \
  Sources/mp4Clipper/Models/*.swift Sources/mp4Clipper/Services/*.swift \
  Sources/mp4Clipper/ViewModels/*.swift Tests/SmokeCheck.swift -o "$check_build/smoke-check"
"$check_build/smoke-check"
