#!/bin/bash
#
# inspect_release_boundary.sh — prove a built product is what it claims to be.
#
# NEXT_LEVEL_PLAN.md Phase 1 requires that "public archive validation fails if the bypass
# symbol is present". "Bypass symbol" here means a marker *string*, not an nm symbol: a
# Release build is stripped, and the TESTFLIGHT_BETA_ACCESS compilation condition leaves no
# trace of itself when it resolves to false — #if that is false compiles to nothing. The
# markers in CosmicRituals/App/ReleaseChannel.swift exist so there is something to detect.
#
# The check is deliberately two-sided. Testing for the absence of the beta marker alone would
# pass on an empty file, a truncated download, or a binary this script failed to read. So the
# expected marker must also be PRESENT: the script has to prove it can see inside the binary
# before it is allowed to report a pass.
#
# This inspects a product. It performs no distribution action and uploads nothing.
#
# Usage:
#   scripts/inspect_release_boundary.sh <path-to.app|path-to.xcarchive> [public|testflight]
#
# The expected channel defaults to "public" — the dangerous direction. Passing "testflight"
# runs the inverse assertion, which is the positive control that proves the check can see
# anything at all.

set -u

TESTING_MARKER="COSMIC_RITUALS_TESTING_ACCESS_BUILD"
PUBLIC_MARKER="COSMIC_RITUALS_PUBLIC_BUILD"
BANNER_COPY="TestFlight testing access"

TARGET="${1:-}"
EXPECTED="${2:-public}"

fail()  { printf '  FAIL  %s\n' "$1"; FAILURES=$((FAILURES + 1)); }
pass()  { printf '  ok    %s\n' "$1"; }
note()  { printf '        %s\n' "$1"; }
FAILURES=0

if [ -z "$TARGET" ]; then
  echo "usage: $0 <path-to.app|path-to.xcarchive> [public|testflight]" >&2
  exit 2
fi

case "$EXPECTED" in
  public|testflight) ;;
  *) echo "expected channel must be 'public' or 'testflight', got '$EXPECTED'" >&2; exit 2 ;;
esac

# ---------------------------------------------------------------- locate the binary
case "$TARGET" in
  *.xcarchive) APP="$TARGET/Products/Applications/CosmicRituals.app" ;;
  *.app)       APP="$TARGET" ;;
  *)           echo "not a .app or .xcarchive: $TARGET" >&2; exit 2 ;;
esac

BINARY="$APP/CosmicRituals"
PLIST="$APP/Info.plist"

echo "Release boundary inspection"
echo "  target:   $TARGET"
echo "  expected: $EXPECTED"
echo

# A missing binary must never read as a pass. This is the failure mode that would quietly
# bless an archive nobody actually checked.
if [ ! -f "$BINARY" ]; then
  fail "no executable at $BINARY — nothing was inspected"
  echo
  echo "RESULT: FAIL ($FAILURES)"
  exit 1
fi
pass "found executable $BINARY"

# ---------------------------------------------------------------- identity, reported not enforced
if [ -f "$PLIST" ]; then
  SHORT=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PLIST" 2>/dev/null || echo '?')
  BUILD=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$PLIST" 2>/dev/null || echo '?')
  BUNDLE=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$PLIST" 2>/dev/null || echo '?')
  note "bundle $BUNDLE, version $SHORT ($BUILD)"
else
  fail "no Info.plist at $PLIST"
  SHORT='?'; BUILD='?'
fi

# ---------------------------------------------------------------- every slice, not just the first
SLICES=$(lipo -info "$BINARY" 2>/dev/null | sed -n 's/.*are: //p; s/.*is architecture: //p')
[ -z "$SLICES" ] && SLICES="(single)"
note "architectures: $SLICES"

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

scan_one() {
  # $1 = path to a single-architecture binary, $2 = label
  local bin="$1" label="$2"
  local testing public banner
  testing=$(strings -a "$bin" | grep -c "$TESTING_MARKER")
  public=$(strings -a "$bin" | grep -c "$PUBLIC_MARKER")
  banner=$(strings -a "$bin" | grep -c "$BANNER_COPY")

  if [ "$EXPECTED" = "public" ]; then
    [ "$testing" -eq 0 ] && pass "$label: no testing-access marker" \
                         || fail "$label: TESTING ACCESS MARKER PRESENT ($testing) — this build bypasses purchase"
    [ "$public" -gt 0 ]  && pass "$label: public marker present ($public)" \
                         || fail "$label: public marker ABSENT — the binary could not be read, so this is not a pass"
    [ "$banner" -eq 0 ]  && pass "$label: no testing banner copy" \
                         || fail "$label: testing banner copy present ($banner)"
  else
    [ "$testing" -gt 0 ] && pass "$label: testing-access marker present ($testing)" \
                         || fail "$label: testing marker ABSENT from a build that should carry it"
    [ "$public" -eq 0 ]  && pass "$label: no public marker" \
                         || fail "$label: public marker present ($public) — configurations are crossed"
  fi
}

if [ "$SLICES" = "(single)" ]; then
  scan_one "$BINARY" "slice"
else
  for arch in $SLICES; do
    THIN="$WORKDIR/$arch"
    if lipo -thin "$arch" "$BINARY" -output "$THIN" 2>/dev/null; then
      scan_one "$THIN" "$arch"
    else
      fail "could not extract slice $arch"
    fi
  done
fi

# ---------------------------------------------------------------- build number reuse
# A build number already recorded as uploaded cannot be used again; App Store Connect will
# reject it, and discovering that during a submission wastes a release window.
if [ "$BUILD" != '?' ]; then
  REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
  CLASH=$(ls "$REPO_ROOT"/RELEASE_*_"$BUILD".md 2>/dev/null | head -1)
  if [ -n "$CLASH" ]; then
    fail "build $BUILD is already recorded as uploaded in $(basename "$CLASH")"
  else
    pass "build $BUILD is not recorded as previously uploaded"
  fi
fi

echo
if [ "$FAILURES" -eq 0 ]; then
  echo "RESULT: PASS"
  exit 0
fi
echo "RESULT: FAIL ($FAILURES)"
exit 1
