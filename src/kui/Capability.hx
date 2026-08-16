package kui;

/**
	What every native capability is declared as.

	## The shape

	A capability is an **interface** extending this one, stating what a platform
	can answer. Its implementations live under `platform.<id>`, a package per
	operating system, each keeping the declaration's own name — so one package may
	hold several capabilities without a naming scheme collapsing:

	```haxe
	package battery;

	interface Battery extends kui.Capability {
		function level():Int;
		function charging():Bool;
	}
	```

	```haxe
	package battery.platform.macos;

	class Battery implements battery.Battery { … }
	```

	`kui.Kui.get(battery.Battery)` resolves `battery.platform.<id>.Battery` for the
	platform being built, and returns it typed as the declaration. Resolution is by
	**name**, which is exactly how `mui.macros.Bind` resolves
	`<backend>.mui.Button` — and for the same reason: a name is the one thing a
	macro can be handed as a string and still act on.

	`get` is a macro rather than `qui`'s `Native.get(cls:Class<T>):T`, because
	`Class<T>` cannot be written for an interface in Haxe. The call site is typed
	all the same; what changes is that a missing implementation is a compile error
	instead of a `null`.

	## Why an interface and not a base class

	Because the implementation is per platform and the call site must not be.
	A base class would make every implementation a subclass of the *same* type,
	which is fine until two platforms need different fields; an interface states
	the contract and leaves each platform its own shape. It also means an
	implementation may extend whatever it likes on its own side.

	## What a capability is for, and what it is not

	It is for reaching the platform: the clipboard, the battery, secure storage,
	haptics, a camera that hands back a file. Non-visual, and small — values
	crossing the boundary should be primitives (`Int`, `Float`, `Bool`, `String`)
	or a `String` carrying something serialised. That constraint is not `kui`'s
	invention: `qui`'s native modules have stated it since they existed, because
	it is what survives every marshalling boundary in this ecosystem, JNI and
	CPPIA included.

	It is **not** for a native *view*. A camera preview or a map inside the view
	tree is a strictly harder problem — three backends render through a closed
	vocabulary checked at macro time, and `pui` would have to decide what it draws
	in place of something it cannot host. Capabilities are keyed by platform and
	resolved by name so that day can reuse both, but it is a separate design.
**/
@:autoBuild(kui.macros.CapabilityMacro.build())
interface Capability {}
