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

## Two example capabilities, and why there are two

`examples/battery` answers a question: `level()`, `charging()`, `powered()`. It
is implemented on six platforms and it proves the resolution, the typing and all
five link channels.

`examples/network` answers a question **whose answer changes while the
application runs** — and that is a different problem. It deliberately has no
callback: a native notification arrives on a thread the system chose, and
calling into Haxe from there means calling into hxcpp's GC from a thread it was
never told about. So the capability stays a synchronous read, and
`network.Watch` builds the watching part in Haxe, where it is portable and where
**stopping** it is something an application can do.

That is what `examples/network-app` shows. The watcher is declared from
`body()` and lives exactly as long as the declaration — `rui`'s keyed lifetime:

```haxe
override function body():View {
    if (watching.get()) lifetime.keep("network", () -> {
        var stop = network.Watch.changes(net, 1000, isOnline -> online.set(isOnline));
        return stop;                       // undone once body() stops asking
    });
    …
}
```

The example also degrades honestly where a timer cannot exist — it takes the
reading and says `kept without a watcher` instead of crashing — and offers a
button as well as a timer to stop declaring, so it can be exercised on a device
where nobody is watching a terminal.

Verified end to end on `cui`, `pui`/macOS, `pui`/Linux-Qt (link taken down and
brought back inside an isolated network namespace), and on a real SailfishOS
phone — `kept`, `released`, and `kept` again on redeclare, the last being a new
watcher rather than a resurrection.

## Where to go next

- [Getting started](getting-started.md) — using a capability in an application
- [Writing a capability](writing-a-capability.md) — the author's side
- [Native payloads](native-payloads.md) — how native code reaches five different
  link steps, which is where most of the work is
- [Limits](limits.md) — what `kui` deliberately does not do
