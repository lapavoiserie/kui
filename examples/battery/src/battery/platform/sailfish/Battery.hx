package battery.platform.sailfish;

/**
	SailfishOS, through sysfs.

	Reached by both `qui` and `pui`'s Qt surface, and they agree on everything
	that matters here: hxcpp only generates C++ on this platform, and **qmake**
	compiles and links all of it. So the payload has a `qmake` section and no
	`hxcpp` one — the latter would be addressed to a step that never runs.

	`kui` renders this into `kui-native.pri` beside the generated Haxe output,
	and the `.pro` includes it. That is the one consumer needing a rendering of
	its own: a `.pro` cannot read JSON, and both of the ones in play collect
	their sources by scanning, so there is no list to append to from outside.

	Separate from `battery.platform.linux.Battery` even though the C++ is shared,
	because they are separate platforms: Sailjail, Harbour's list of allowed
	libraries and Silica exist on one side only. Sharing the source file is how
	they say what they have in common without pretending to be the same thing.
**/
@:kuiNative({
	qmake: {
		files: ["native/battery_sysfs.cpp"],
	},
})
@:cppFileCode('extern "C" int kui_battery_level();
extern "C" bool kui_battery_charging();')
class Battery implements battery.Battery {
	public function new() {}

	public function level():Int
		return untyped __cpp__("kui_battery_level()");

	public function charging():Bool
		return untyped __cpp__("kui_battery_charging()");
}
