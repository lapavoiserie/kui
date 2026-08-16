# kui

Native capabilities for [La Pavoiserie](https://github.com/lapavoiserie) —
**written once, keyed by platform, used from every backend.**

Before this, reaching the platform meant choosing a backend and staying there.
`qui` had a native-module system that was `qui`'s alone, tied to a hard-coded
directory and invisible to everyone else. `sui` had a `swift/` folder whose
companion metadata only a decommissioned transpiler honoured. `aui`, `wui` and
`cui` had nothing. The same camera got written six times, or not at all — and
`pui`, which draws its own widgets and has no host toolkit to borrow from, would
have written it a seventh.

## The shape of it

An author declares an API once, as an interface naming no platform:

```haxe
package battery;

interface Battery extends kui.Capability {
	function level():Int;      // 0..100, or -1 where there is no battery
	function charging():Bool;
}
```

then one implementation per operating system, at `p.platform.<id>.Name`, each
saying what the build has to do for it:

```haxe
package battery.platform.macos;

@:kuiNative({
	hxcpp: {files: ["native/battery_mac.mm"], libs: ["-framework", "IOKit"]},
	xcode: {frameworks: ["IOKit"]},
})
class Battery implements battery.Battery {
	public function new() {}
	public function level():Int return untyped __cpp__("kui_battery_level()");
	public function charging():Bool return untyped __cpp__("kui_battery_charging()");
}
```

An application asks for the declaration and gets the implementation for whatever
it is being built for:

```haxe
var battery = kui.Kui.get(battery.Battery);
trace(battery.level());
```

Fully typed — arity, argument types and return types all come from the
declaration.

## Why the platform, and not the backend

Because that is what makes an implementation reusable.
`battery.platform.macos.Battery` talks to IOKit — not to SwiftUI, not to a
terminal — so it serves every backend that builds for macOS. `examples/app` is
one source built five ways, and none of the build files names another's backend:

| Build | Backend | What links |
|---|---|---|
| `build-pui.hxml` | `pui` | hxcpp |
| `build-cui.hxml` | `cui` | hxcpp |
| `build-sui.hxml` | `sui` | Xcode |
| `build-aui.hxml` | `aui` | Gradle |
| `build-wui.hxml` | `wui` | MSBuild |

The first three reach macOS and share one `battery_mac.mm`. Nothing was written
twice.

That is also the answer for `pui`, which has no host toolkit of its own: it
reuses what was written for the *platform*.

## A missing implementation is a compile error

```
battery.Battery has no implementation for "browser".
  It implements: android, linux, macos, sailfish, windows.
  kui looked for battery.platform.browser.Battery.
```

Never a runtime `null`, never a marker on screen. Where a feature is genuinely
optional, `Kui.supports(battery.Battery)` folds to a compile-time `true`/`false`
and dead-code elimination removes the rest.

## Where to go next

- [Getting started](getting-started.md) — using a capability in an application
- [Writing a capability](writing-a-capability.md) — the author's side
- [Native payloads](native-payloads.md) — how native code reaches five different
  link steps, which is where most of the work is
- [Limits](limits.md) — what `kui` deliberately does not do
