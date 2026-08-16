package battery.platform.linux;

/**
	Desktop Linux, through sysfs.

	The same C++ file as `battery.platform.sailfish.Battery`, and a separate
	class on purpose. They are separate platforms — Sailjail, Silica and
	Harbour's list of allowed libraries exist on one side only — and sharing the
	source file is how the two say what they have in common without pretending to
	be the same thing. The day one of them needs UPower, only that one changes.

	Reached through `pui`'s Qt surface, where hxcpp only generates C++ and qmake
	compiles and links it. Hence a `qmake` section and no `hxcpp` one.

	Which of the two a Qt build is for cannot be worked out in Haxe:
	`build-pui-linux.hxml` and `build-pui-sailfish.hxml` are identical apart from
	`-D kui_platform`, because only `DEFINES += PUI_SAILFISH` in the `.pro`
	separates them — the C++ preprocessor, long after macros have run. So the
	build file says which, by name.
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
