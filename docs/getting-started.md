# Getting started

## Adding kui to a build

`kui` is a haxelib. An application needs it on the classpath and needs its
backend to have declared which platform the build is for:

```
-lib kui
--macro pui.kui.Platform.registerWithKui()
```

Every backend has that macro under its own name — `sui.kui.Platform`,
`aui.kui.Platform`, `wui.kui.Platform`, `cui.kui.Platform`, `qui.kui.Platform`.
Applications scaffolded by `mui init` get the line already, because it lives in
each backend's own `init.hxml`.

**On Qt, one more line is required:**

```
-D kui_platform=sailfish     # or linux
```

Nothing in Haxe can tell SailfishOS from desktop Linux — the two build files are
otherwise identical, and only `DEFINES += PUI_SAILFISH` in the `.pro` separates
them, which is the C++ preprocessor, long after macros have run. `kui` asks
rather than guesses. See [Platforms](platforms.md).

## Adding a capability

Either as a library:

```
-lib kui-battery
```

or, while prototyping, as a directory in the application:

```
-cp capabilities
```

Both are discovered the same way, and a capability developed the second way
becomes the first without changing a line — its native paths are resolved
against the *library root*, never the working directory.

## Using it

```haxe
import battery.Battery;

class Main {
	static function main() {
		var battery = kui.Kui.get(Battery);
		trace(battery.level());
	}
}
```

`Kui.get` takes the **declaration's type path**, not a value, and expands to a
typed cast of the implementation for this build's platform. It is a macro
because `Class<T>` cannot be written for an interface in Haxe.

## When a platform has no implementation

The build fails, at the line that reached for it, naming both sides:

```
battery.Battery has no implementation for "browser".
  It implements: android, linux, macos, sailfish, windows.
  kui looked for battery.platform.browser.Battery.
```

If that is a legitimate state rather than an oversight, ask first:

```haxe
if (kui.Kui.supports(Battery)) {
	trace(kui.Kui.get(Battery).level());
} else {
	trace("no battery reading on this platform");
}
```

`supports` folds to a constant at compile time, so the branch that cannot exist
is removed rather than merely skipped.
