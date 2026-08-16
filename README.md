# kui

Native capabilities for [La Pavoiserie](https://github.com/lapavoiserie) —
**written once, keyed by platform, used from every backend.**

Before this, reaching the platform meant choosing a backend and staying there.
`qui` had a native-module system that was `qui`'s alone; `sui` had a `swift/`
folder whose companion metadata only a decommissioned transpiler honoured; the
others had nothing. The same camera got written six times, or not at all — and
`pui`, which draws its own widgets and has no host toolkit to borrow from, would
have written it a seventh.

## What an author writes

A declaration, naming no platform:

```haxe
package battery;

interface Battery extends kui.Capability {
	function level():Int;
	function charging():Bool;
}
```

An implementation per operating system, at `p.platform.<id>.Name`, declaring what
the build has to do for it:

```haxe
package battery.platform.macos;

@:kuiNative({
	hxcpp: {files: ["native/battery_mac.mm"], libs: ["-framework", "IOKit"]},
})
class Battery implements battery.Battery {
	public function new() {}
	public function level():Int return untyped __cpp__("kui_battery_level()");
	public function charging():Bool return untyped __cpp__("kui_battery_charging()");
}
```

## What an application writes

```haxe
var battery = kui.Kui.get(battery.Battery);
trace(battery.level());
```

Fully typed — arity, argument types and return types all come from the
declaration. And a capability this platform does not implement is a **compile
error at the line that reached for it**:

```
battery.Battery has no implementation for "browser".
  It implements: macos.
  kui looked for battery.platform.browser.Battery.
```

Never a runtime `null`, never a marker on screen. `Kui.supports(battery.Battery)`
folds to a compile-time `true`/`false` for a feature that is genuinely optional.

## Why the platform and not the backend

Because that is what makes an implementation reusable. `battery.platform.macos`
talks to IOKit — not to SwiftUI, not to a terminal — so it serves every backend
that builds for macOS. `examples/app` is the same source built twice:

```
haxe build-pui.hxml   # a native window, CoreGraphics
haxe build-cui.hxml   # a terminal
```

Both link the same `battery_mac.mm`, and both print `kui: level 100, charging
false`. Nothing was written twice, and neither build file names the other's
backend.

That is also the answer for `pui`, which has no host toolkit of its own: it
reuses what was written for the platform, not for a backend.

## Where it lives

A capability is a **haxelib** (`-lib kui-battery`) or a **local directory** in
the application, for prototyping. Both are discovered the same way.

## What is not here

**Native views.** A camera preview or a map inside the view tree is a strictly
harder problem: three backends render through a closed vocabulary checked at
macro time, and `pui` would have to decide what it draws in place of something it
cannot host. Capabilities are keyed by platform and resolved by name so that day
can reuse both, but it is a separate design.

**A sandbox.** A capability is arbitrary native code compiled into the process.
That is a trust boundary, stated rather than policed — the same one any native
dependency carries.
