#!/usr/bin/env bash
# What kui has to keep true, checked without a device or a toolchain.
#
# Deliberately not a unit-test framework: almost everything here happens at
# macro time, and what needs asserting is what the compiler *says* — that a
# missing implementation is an error naming both sides, that an unknown platform
# is refused, that the payload comes out in the shape a link step can read. A
# runner that could only inspect values at runtime would check none of it.
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
cd "$here"
out="$(mktemp -d)"
trap 'rm -rf "$out"' EXIT

failures=0
pass() { echo "  ok   $1"; }
fail() { echo "  FAIL $1"; failures=$((failures + 1)); }

# Compile Check.hx for a platform, in interpreted mode: no C++ toolchain needed,
# and the macros -- which are all of the interesting part -- run either way.
build() {
	haxe -cp . -cp ../src -D kui_platform="$1" ${2:-} --main Check --interp 2>&1
}

echo "resolution"
if build macos | grep -q "level "; then
	pass "macos resolves battery.platform.macos.Battery"
else
	fail "macos should resolve, and did not"
fi

echo
echo "a platform with no implementation"
message="$(build browser)"
for expected in \
	'has no implementation for "browser"' \
	"It implements: macos" \
	"kui looked for battery.platform.browser.Battery"
do
	if grep -qF "$expected" <<<"$message"; then
		pass "says: $expected"
	else
		fail "should say: $expected"
	fi
done

echo
echo "a platform kui has never heard of"
message="$(build macOS)"          # right platform, wrong case: the silent failure
if grep -qF 'does not know the platform "macOS"' <<<"$message"; then
	pass "a misspelled id is refused rather than silently unresolved"
else
	fail "a misspelled id should be refused"
fi
if grep -qF "kui_platform_unchecked" <<<"$(build madeup)"; then
	pass "and the message names the way past"
else
	fail "the message should name -D kui_platform_unchecked"
fi

echo
echo "no platform at all"
# Captured first, then matched: `pipefail` is on, and haxe exits non-zero on a
# compile error — piping it straight into grep would report the compiler's
# failure as the pipeline's, which is exactly the failure being asserted.
message="$(haxe -cp . -cp ../src --main Check --interp 2>&1)"
if grep -qF "does not know which platform" <<<"$message"; then
	pass "absence is refused, not defaulted"
else
	fail "a build with no platform should be refused"
fi

echo
echo "the payload reaches a link step"
# The qmake rendering is the one that also copies, so it is the one worth
# checking on disk: a .pri naming an absolute host path would pass a string
# comparison and fail inside the build container.
haxe -cp . -cp ../src -D kui_platform=sailfish --main Check -cpp "$out" -D no-compilation > /dev/null 2>&1
if [ -f "$out/kui-payload.json" ]; then
	pass "kui-payload.json is written beside the output"
else
	fail "kui-payload.json should be written beside the output"
fi
if [ -f "$out/kui-native.pri" ]; then
	pass "kui-native.pri is rendered for qmake"
else
	fail "kui-native.pri should be rendered for qmake"
fi
if [ -f "$out/kui-native/battery_platform_sailfish_Battery/battery_stub.cpp" ]; then
	pass "the source is copied into the output, under the declarer's own name"
else
	fail "the source should be copied into the output"
fi
if grep -q '\$\$PWD/kui-native/' "$out/kui-native.pri" 2>/dev/null; then
	pass "and named with \$\$PWD, which survives the build container"
else
	fail "the .pri must not name an absolute host path: qmake runs elsewhere"
fi

echo
echo "a build that uses no capability"
haxe -cp ../src -D kui_platform=macos --main kui.Kui -cpp "$out/none" -D no-compilation > /dev/null 2>&1
if [ ! -f "$out/none/kui-payload.json" ]; then
	pass "writes nothing, so every consumer can hook unconditionally"
else
	fail "a build with no capability should write no sidecar"
fi

echo
if [ "$failures" -eq 0 ]; then
	echo "all checks passed"
else
	echo "$failures check(s) failed"
fi
exit "$failures"
