# Writing a capability

## The declaration

An interface extending `kui.Capability`, naming no platform and no backend:

```haxe
package battery;

interface Battery extends kui.Capability {
	function level():Int;      // 0..100, or -1 where there is no battery
	function charging():Bool;
}
```

Keep the types primitive where you can. Everything crosses a language boundary
on at least one platform — C++, Swift, Kotlin — and `Int`, `Float`, `Bool` and
`String` are what marshals without ceremony everywhere.

Say what the odd values mean, in the declaration, and hold every implementation
to it. `level()` returning `-1` for "no battery here" is part of the contract; a
platform that cannot answer must not invent a plausible number.

## The implementations

One per operating system, at `p.platform.<id>.Name`:

```
battery/
  Battery.hx                       the declaration
  platform/
    macos/Battery.hx
    windows/Battery.hx
    android/Battery.hx
    sailfish/Battery.hx
  native/
    battery_mac.mm
    battery_win.cpp
    battery_sysfs.cpp
    BatteryAndroid.kt
```

**A package per platform, the class keeping its name** — `platform.macos.Battery`
rather than `platform.Macos`. One package may then hold several capabilities
(`Accelerometer`, `Gyroscope`) without a naming scheme collapsing.

Each implementation needs a **constructor taking no arguments**. `kui`
constructs it itself, through `Type.createInstance`, and checks for the
constructor at the class rather than letting it fail at runtime on one platform
for whoever ships there.

## Sharing a source file between platforms

Two platforms may share their native code and still be two classes. The example
capability does exactly that for Linux and SailfishOS: both read sysfs, both
name `native/battery_sysfs.cpp`, and they stay separate because Sailjail, Silica
and Harbour's allowed libraries exist on one side only. The day one of them
needs UPower, only that one changes.

## Declaring what the build must do

See [Native payloads](native-payloads.md). The short version: `@:kuiNative`,
keyed by toolchain, with paths relative to the library root.

## What to leave out

An implementation should not reach for the host's window. A share sheet wants a
`UIViewController`, an Android file picker wants an `Activity`, a Qt dialog
wants a parent widget — and the moment one of those is needed, "a capability
depends on no backend" is false. `kui` has no window-handle protocol today, and
that is a stated boundary rather than an oversight: the Android battery example
reads sysfs precisely because `BatteryManager` would have needed a `Context`.

If the capabilities people actually want all turn out to need a window handle,
that boundary is the wrong one and should move before more is built on it.

## Shipping it

As a haxelib, named `kui-<name>`:

```json
{
  "name": "kui-battery",
  "classPath": "src",
  "dependencies": { "kui": "" }
}
```

`native/` sits beside `src/`, and paths in `@:kuiNative` are relative to the
directory holding `haxelib.json`. Nothing has to be copied into an application
that uses it — which is the single most important difference from `qui`'s old
`modules/native` scan, whose working-directory-relative paths meant an extension
could never come from a library at all.
