#!/bin/sh
set -eu
repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
exec xcodebuild \
  -project "$repo_dir/ios/GODIEOR.xcodeproj" \
  -scheme GODIEOR \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$repo_dir/work/DerivedData" \
  CODE_SIGNING_ALLOWED=NO build
