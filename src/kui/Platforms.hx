package kui;

/**
	The platforms a capability may be implemented for.

	## Why a closed list, here of all places

	`mui` deliberately holds **no** list of backends: a backend is a product
	anyone may release, and a hub that enumerates them is a hub every new one has
	to be added to. That reasoning does not carry over. An operating system is a
	fact of the world, not a product of this ecosystem, and the list changes about
	once a decade.

	It earns its place by catching the one failure resolution by name cannot see.
	`battery.platform.macOS.Battery` and `battery.platform.macos.Battery` are both
	perfectly good Haxe, and **neither would ever be selected** — `kui` looks for
	the id it was given and finds nothing, so a capability that was written,
	compiled and shipped simply never resolves. A misspelling that produces
	silence is worse than one that produces an error.

	`-D kui_platform_unchecked` is the way past, for someone porting to a platform
	this list has not heard of. It is the only way past, and it is deliberate: an
	escape hatch that is easy to reach for is a list that means nothing.

	## Why the operating system and not the toolkit

	Because that is what makes a capability reusable. `battery.platform.macos` is
	written against IOKit, so it serves a `sui` application and `pui`'s macOS
	surface equally — neither of them is what a battery talks to. Keying by
	backend would give six copies of the same file.

	The cost is that one platform can be reached through several link steps —
	macOS through hxcpp under `pui` and through Xcode under `sui` — which is why
	`kui.build.Payload` is keyed by **toolchain** rather than by platform.
**/
class Platforms {
	public static final IDS:Array<{id:String, name:String, note:String}> = [
		{id: "macos", name: "macOS", note: "Reached through hxcpp under pui and cui, through Xcode under sui."},
		{id: "ios", name: "iOS", note: "Xcode under sui; an application build script under pui."},
		{id: "visionos", name: "visionOS", note: "Xcode under sui, which reads -D sui_visionos. Separate from ios: the frameworks differ and a capability written for one has no reason to compile for the other."},
		{id: "android", name: "Android", note: "Gradle under aui; an application build script under pui."},
		{id: "windows", name: "Windows", note: "MSBuild under wui; hxcpp under pui and cui."},
		{id: "linux", name: "Linux", note: "hxcpp under cui; qmake under pui."},
		{id: "sailfish", name: "SailfishOS", note: "qmake, under qui and under pui. Not the same platform as linux: Silica, Maliit, Sailjail and Harbour's allowed libraries exist on one side only."},
		{id: "browser", name: "the browser", note: "No native link step at all: a capability here is plain Haxe over the DOM."},
	];

	/** Whether an id is one this list knows. **/
	public static function known(id:String):Bool {
		for (platform in IDS) if (platform.id == id) return true;
		return false;
	}

	/** Every id, for a message that helps rather than merely refuses. **/
	public static function ids():Array<String>
		return [for (platform in IDS) platform.id];
}
