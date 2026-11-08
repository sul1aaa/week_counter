#!/bin/sh
# Frames the screenshots from test_driver/screenshots_test.dart for the App Store:
# caption, rounded screen, black background, plus a picture of the widgets.
#
#   store/frame/make.sh <folder with en/ and ru/ screenshots>
#
# Writes store/screenshots/en and store/screenshots/ru. Needs Xcode (macOS 14+).
set -e
raw=$(cd "$1" && pwd)
cd "$(dirname "$0")/../.."
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# The widget's own views, minus what only builds inside a widget extension: the
# widget family comes in as a property, and the Widget and previews are dropped.
python3 -I - ios/WeekCounterWidget/WeekCounterWidget.swift "$tmp/widget.swift" <<'PY'
import sys
s = open(sys.argv[1], encoding="utf-8").read()
s = s[:s.index("struct WeekCounterWidget: Widget")]
old = "@Environment(\\.widgetFamily) private var family"
assert old in s, "the widget no longer reads widgetFamily; update store/frame/make.sh"
open(sys.argv[2], "w", encoding="utf-8").write(s.replace(old, "var family: WidgetFamily"))
PY
xcrun swiftc -target arm64-apple-macos14 "$tmp/widget.swift" store/frame/main.swift -o "$tmp/compose"
for lang in en ru; do
  "$tmp/compose" "$raw/$lang" assets/fonts design/app-icon.png "store/screenshots/$lang" "$lang"
done
