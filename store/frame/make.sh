#!/bin/sh
# Frames the screenshots from test_driver/screenshots_test.dart for the App Store:
# caption, rounded screen, black background, plus a picture of the widgets.
#
#   store/frame/make.sh <folder with en/ and ru/ screenshots>
#
# Writes store/screenshots/6.9-inch (1320 × 2868) and 6.3-inch (1206 × 2622), each with en/ and
# ru/. App Store Connect asks for the 6.3" size; the 6.9" one is for large-display iPhones.
# Needs Xcode (macOS 14+).
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
  "$tmp/compose" "$raw/$lang" assets/fonts design/app-icon.png "store/screenshots/6.9-inch/$lang" "$lang"
  # Same proportions within 0.1%, so a plain resize.
  mkdir -p "store/screenshots/6.3-inch/$lang"
  for f in "store/screenshots/6.9-inch/$lang"/*.png; do
    sips -z 2622 1206 "$f" --out "store/screenshots/6.3-inch/$lang/$(basename "$f")" >/dev/null
  done
done
